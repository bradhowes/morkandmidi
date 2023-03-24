// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import os

/**
 Connects to any and all MIDI sources, processing all messages it sees. There really is no API right now. Just create
 an instance and set the `receiver` (aka delegate) to receive the incoming MIDI traffic.
 */
public final class MIDI: NSObject {
  private let log: OSLog = Logging.logger("MIDI")

  private var ourUniqueId: MIDIUniqueID
  private let clientName: String
  private lazy var inputPortName = clientName + " In"
  private let midiProtocol: MIDIProtocolID
  private let parser = MIDI2Parser()

  private var client: MIDIClientRef = MIDIClientRef()
  private var inputPort: MIDIPortRef = MIDIEndpointRef()
  private var virtualMidiIn: MIDIEndpointRef = MIDIEndpointRef()

  /// Collection of endpoint IDs and the last channel ID found in a MIDI message from the endpoint
  @objc dynamic
  public private(set) var channels = [MIDIUniqueID: Int]()
  public private(set) var refCons = [MIDIUniqueID: UnsafeMutablePointer<MIDIUniqueID>]()

  /// Collection of connection IDs that are connected to our virtual endpoint.
  @objc dynamic
  public private(set) var activeConnections = Set<MIDIUniqueID>()

  /**
   Current state of a MIDI device
   */
  public struct DeviceState: Equatable {
    /// Unique ID for the device endpoint to connect to
    let uniqueId: MIDIUniqueID
    /// The display name for the endpoint
    let displayName: String
    /// True if connected to it and able to receive MIDI commands from endpoint
    let connected: Bool
    /// Last seen channel in a MIDI message from this device
    let channel: Int?
  }

  /// Obtain current state of MIDI device connections
  public var devices: [DeviceState] {
    Sources().map { endpoint in
      let uniqueId = endpoint.uniqueId
      let displayName = endpoint.displayName
      let connected = activeConnections.contains(uniqueId)
      let channel = channels[uniqueId]
      os_log(.info, log: log, "DeviceEntry(%d '%{public}s' %d", uniqueId, displayName, connected)
      return DeviceState(uniqueId: uniqueId, displayName: displayName, connected: connected, channel: channel)
    }
  }

  /// Delegate which will receive incoming MIDI messages
  public weak var receiver: Receiver?

  /// Delegate which will receive notification about MIDI connectivity
  public weak var monitor: Monitor?

  /**
   Create new instance. Initializes CoreMIDI and creates an input port to receive MIDI traffic
   */
  public init(clientName: String, uniqueId: MIDIUniqueID, midiProtocol: MIDIProtocolID = ._1_0) {
    self.clientName = clientName
    self.ourUniqueId = uniqueId
    self.midiProtocol = midiProtocol
    super.init()
  }

  /**
   Tear down MIDI plumbing.
   */
  deinit {
    stop()
    if client != MIDIClientRef() { MIDIClientDispose(client) }
    monitor?.deinitialized()
  }
}

public extension MIDI {

  /**
   Begin MIDI processing.
   */
  func start() {
    createClient()
    initialize()
  }

  /**
   End MIDI processing.
   */
  func stop() {
    if inputPort != MIDIEndpointRef() {
      MIDIEndpointDispose(inputPort)
      inputPort = MIDIEndpointRef()
    }

    if virtualMidiIn != MIDIEndpointRef() {
      MIDIEndpointDispose(virtualMidiIn)
      virtualMidiIn = MIDIEndpointRef()
    }
  }

  /**
   Associate a channel number with the unique ID of a connection endpoint.

   - parameter uniqueId: the uniqueId of the endpoints
   - parameter channel: the channel number
   */
  func updateEndpointChannel(uniqueId: MIDIUniqueID, channel: Int) {
    channels[uniqueId] = channel
  }
}

private extension MIDI {

  func initialize() {
    enableNetworkSession()
    createInputPort()
    createVirtualDestination()
    monitor?.initialized(uniqueId: ourUniqueId)
    updateConnections()
  }

  func createClient() {
    let err = MIDIClientCreateWithBlock(clientName as CFString, &client) { [weak self] in
      guard let self = self else { return }
      let messageID = $0.pointee.messageID
      os_log(.debug, log: self.log, "client callback: %{public}s", messageID.tag)
      if messageID  == .msgSetupChanged {
        self.updateConnections()
        self.monitor?.updatedDevices()
      }
    }

    err.wasSuccessful(log, "MIDIClientCreateWithBlock")
  }

  func updateConnections() {
    os_log(.info, log: log, "updateConnections")

    let active = Sources()
    let inactive = activeConnections.subtracting(active.uniqueIds)

    let changed: Int = (active.map { connectSource(endpoint: $0) ? 1 : 0 }.reduce(0, +) +
                        inactive.map { disconnectSource(uniqueId: $0) ? 1 : 0 }.reduce(0, +))
    if changed != 0 {
      monitor?.updatedConnections()
    }
  }

  func connectSource(endpoint: MIDIEndpointRef) -> Bool {
    let name = endpoint.displayName
    let uniqueId = endpoint.uniqueId
    os_log(.info, log: log, "connectSource - %d %{public}s", uniqueId, name)
    guard uniqueId != ourUniqueId && !activeConnections.contains(uniqueId) else {
      os_log(.debug, log: log, "already connected to endpoint %d '%{public}s'", uniqueId, name)
      return false
    }

    os_log(.info, log: log, "connecting endpoint %d '%{public}s'", uniqueId, name)
    let refCon = boxUniqueId(uniqueId)
    refCons[uniqueId] = refCon

    return MIDIPortConnectSource(inputPort, endpoint, refCon)
      .wasSuccessful(log, "MIDIPortConnectSource")
  }

  func disconnectSource(uniqueId: MIDIUniqueID) -> Bool {
    guard activeConnections.contains(uniqueId) else {
      os_log(.debug, log: log, "not connected to %d", uniqueId)
      return false
    }

    activeConnections.remove(uniqueId)
    guard let endpoint = Sources().first(where: { $0.uniqueId == uniqueId }) else {
      os_log(.error, log: log, "unable to disconnect - no endpoint with uniqueId %d", uniqueId)
      return false
    }

    os_log(.info, log: log, "disconnecting endpoint %d '%{public}s'", uniqueId, endpoint.displayName)

    return MIDIPortDisconnectSource(virtualMidiIn, endpoint)
      .wasSuccessful(log, "MIDIPortDisconnectSource")
  }

  func boxUniqueId(_ uniqueId: MIDIUniqueID) -> UnsafeMutablePointer<MIDIUniqueID> {
    let refCon = UnsafeMutablePointer<MIDIUniqueID>.allocate(capacity: 1)
    refCon.initialize(to: uniqueId)
    return refCon
  }

  func unboxRefCon(_ refCon: UnsafeRawPointer?) -> MIDIUniqueID {
    guard let uniqueId = refCon?.assumingMemoryBound(to: MIDIUniqueID.self).pointee else { fatalError() }
    return uniqueId
  }

  func createInputPort() {
    let err = MIDIInputPortCreateWithProtocol(client, inputPortName as CFString, ._2_0,
                                              &inputPort) { [weak self] eventListPointer, refCon in
      guard let self = self else { return }
      self.processEventList(eventList: eventListPointer, uniqueId: self.unboxRefCon(refCon))
    }

    if err.wasSuccessful(log, "MIDIInputPortCreateWithProtocol") {
      initializeInput(inputPort)
    }
  }

  func createVirtualDestination() {
    let err = MIDIDestinationCreateWithProtocol(client, inputPortName as CFString, midiProtocol,
                                                &virtualMidiIn) { [weak self] eventListPointer, refCon in
      guard let self = self else { return }
      self.processEventList(eventList: eventListPointer, uniqueId: self.unboxRefCon(refCon))
    }

    if err.wasSuccessful(log, "MIDIDestinationCreateWithBlock") {
      initializeInput(virtualMidiIn)
    }
  }

  func processEventList(eventList: UnsafePointer<MIDIEventList>, uniqueId: MIDIUniqueID) {
    eventList.unsafeSequence().forEach { eventPacket in
      parser.parse(midi: self, uniqueId: uniqueId, words: eventPacket.words())
    }
  }

  func initializeInput(_ endpoint: MIDIEndpointRef) {
    os_log(.debug, log: log, "initializeInput")
    let newUniqueId = endpoint.uniqueId

    // Try to reuse our previous uniqueId. If that fails, use the new one
    if MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyUniqueID, ourUniqueId)
      .wasSuccessful(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyUniqueID)") {
      os_log(.debug, log: log, "using newUniqueId - %d", newUniqueId)
      ourUniqueId = newUniqueId
    }

    MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyAdvanceScheduleTimeMuSec, 1)
      .wasSuccessful(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyAdvanceScheduleTimeMuSec)")
    MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyReceivesClock, 1)
      .wasSuccessful(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesClock)")
    MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyReceivesNotes, 1)
      .wasSuccessful(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesNotes)")
    MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyReceivesProgramChanges, 1)
      .wasSuccessful(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesProgramChanges)")
    MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyMaxReceiveChannels, 16)
      .wasSuccessful(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyMaxReceiveChannels)")
  }

  func enableNetworkSession() {
    let mns = MIDINetworkSession.default()
    mns.isEnabled = true
    mns.connectionPolicy = .anyone
    os_log(.debug, log: log, "clientName: %{public}s", clientName)
    os_log(.debug, log: log, "net session enabled: %d", mns.isEnabled)
    os_log(.debug, log: log, "net session networkPort: %d", mns.networkPort)
    os_log(.debug, log: log, "net session networkName: %{public}s", mns.networkName)
    os_log(.debug, log: log, "net session localName: %{public}s", mns.localName)
  }
}
