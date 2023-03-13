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

  private var client: MIDIClientRef = MIDIClientRef()
  private var virtualMidiIn: MIDIEndpointRef = MIDIEndpointRef()
  private var inputPort: MIDIPortRef = MIDIPortRef()

  /// Collection of endpoint IDs and the last channel ID found in a MIDI message from the endpoint
  @objc dynamic
  public private(set) var channels = [MIDIUniqueID: Int]()

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
  public init(clientName: String, uniqueId: MIDIUniqueID) {
    self.clientName = clientName
    self.ourUniqueId = uniqueId
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
    if inputPort != MIDIPortRef() {
      MIDIPortDispose(inputPort)
      inputPort = MIDIPortRef()
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
    enableNetwork()
    createVirtualDestination()
    createInputPort()
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

    logIfErr(log, "MIDIClientCreateWithBlock", err)
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
    guard uniqueId != ourUniqueId && !activeConnections.contains(uniqueId) else {
      os_log(.debug, log: log, "already connected to endpoint %d '%{public}s'", uniqueId, name)
      return false
    }

    activeConnections.insert(uniqueId)

    os_log(.info, log: log, "connecting endpoint %d '%{public}s'", uniqueId, name)
    logIfErr(log, "MIDIPortConnectSource", MIDIPortConnectSource(virtualMidiIn, endpoint, boxUniqueId(uniqueId)))

    return true
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
    logIfErr(log, "MIDIPortDisconnectSource", MIDIPortDisconnectSource(inputPort, endpoint))

    return true
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

  func createVirtualDestination() {
    let err = MIDIDestinationCreateWithBlock(client, inputPortName as CFString,
                                             &virtualMidiIn) { [weak self] packetList, refCon in
      guard let self = self else { return }
      self.processPackets(packetList: packetList.pointee, uniqueId: self.unboxRefCon(refCon))
    }

    if !logIfErr(log, "MIDIDestinationCreateWithBlock", err) {
      initializeInput(virtualMidiIn)
    }
  }

  func createInputPort() {
    let err = MIDIInputPortCreateWithBlock(client, inputPortName as CFString,
                                           &inputPort) { [weak self] packetList, refCon in
      guard let self = self else { return }
      self.processPackets(packetList: packetList.pointee, uniqueId: self.unboxRefCon(refCon))
    }

    if !logIfErr(log, "MIDIInputPortCreateWithBlock", err) {
      initializeInput(inputPort)
    }
  }

  func initializeInput(_ endpoint: MIDIEndpointRef) {
    let newUniqueId = endpoint.uniqueId

    // Try to reuse our previous uniqueId. If that fails, use the new one
    if logIfErr(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyUniqueID)",
                MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyUniqueID, ourUniqueId)) {
      ourUniqueId = newUniqueId
    }

    logIfErr(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyAdvanceScheduleTimeMuSec)",
             MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyAdvanceScheduleTimeMuSec, 1))
    logIfErr(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesClock)",
             MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyReceivesClock, 1))
    logIfErr(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesNotes)",
             MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyReceivesNotes, 1))
    logIfErr(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesProgramChanges)",
             MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyReceivesProgramChanges, 1))
    logIfErr(log, "MIDIObjectSetIntegerProperty(kMIDIPropertyMaxReceiveChannels)",
             MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyMaxReceiveChannels, 16))
  }

  func enableNetwork() {
    let mns = MIDINetworkSession.default()
    mns.isEnabled = true
    mns.connectionPolicy = .anyone
    os_log(.debug, log: log, "clientName: %{public}s", clientName)
    os_log(.debug, log: log, "net session enabled: %d", mns.isEnabled)
    os_log(.debug, log: log, "net session networkPort: %d", mns.networkPort)
    os_log(.debug, log: log, "net session networkName: %{public}s", mns.networkName)
    os_log(.debug, log: log, "net session localName: %{public}s", mns.localName)
  }

  func processPackets(packetList: MIDIPacketList, uniqueId: MIDIUniqueID) {
    os_log(.debug, log: log, "processPackets - numPackets: %d uniqueId: %d", packetList.numPackets, uniqueId)
    packetList.parse(midi: self, uniqueId: uniqueId)
  }
}
