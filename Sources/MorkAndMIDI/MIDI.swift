// Copyright © 2023 Brad Howes. All rights reserved.

import os.log
import CoreMIDI

/**
 Connects to any and all MIDI sources, processing all messages it sees. There really is no API right now. Just create
 an instance and set the `receiver` (aka delegate) to receive the incoming MIDI traffic.
 */
public final class MIDI: NSObject {
  private let log: OSLog = Logging.logger("MIDI")
  /// The MIDI protocol we are expecting.
  public let midiProto: MIDIProto
  /// Collection of endpoint unique IDs and the last channel ID found in a MIDI message from that endpoint
  @objc dynamic
  public private(set) var channels = [MIDIUniqueID: Int]()
  /// MIDI v2 groups that have been seen
  @objc dynamic
  public private(set) var groups = [MIDIUniqueID: Int]()
  /// Collection of connection IDs that are connected to our input port.
  @objc dynamic
  public private(set) var activeConnections = Set<MIDIUniqueID>()
  /// Returns `true` when the MIDI service is running and accepting messages
  public var isRunning: Bool { inputPort != MIDIPortRef() }
  /// The model identifier assigned to the input port
  public var model: String = "" {
    didSet {
      if inputPort != MIDIPortRef() {
        inputPort.model = model
      }
    }
  }
  /// The manufacturer identifier assigned to the input port
  public var manufacturer: String = "" {
    didSet {
      if inputPort != MIDIPortRef() {
        inputPort.manufacturer = manufacturer
      }
    }
  }
  /// Configure if network connections are allowed
  public var enableNetworkConnections: Bool = true {
    didSet {
      configureNetworkConnections()
    }
  }

  internal var client: MIDIClientRef = .init()
  internal var inputPort: MIDIPortRef = .init()
  internal var ourUniqueId: MIDIUniqueID
  internal let clientName: String
  internal var refCons = [MIDIUniqueID: UnsafeMutablePointer<MIDIUniqueID>]()

  private lazy var inputPortName = clientName + " In"
  private lazy var parser1: MIDI1Parser = .init(midi: self)
  private lazy var parser2: MIDI2Parser = .init(midi: self)

  /**
   Current state of a MIDI connection to the inputPort
   */
  public struct SourceConnectionState: Equatable {
    /// Unique ID for the device endpoint to connect to
    public let uniqueId: MIDIUniqueID
    /// The display name for the endpoint
    public let displayName: String
    /// True if connected to it and able to receive MIDI commands from endpoint
    public let connected: Bool
    /// Last seen channel in a MIDI message from this device
    public let channel: Int?
    /// Last seen group in a MIDI message from this device
    public let group: Int?
  }

  /// Obtain current state of MIDI connections
  public var sourceConnections: [SourceConnectionState] {
    KnownSources.all.map { endpoint in
      let uniqueId = endpoint.uniqueId
      let displayName = endpoint.displayName
      let connected = activeConnections.contains(uniqueId)
      let group = groups[uniqueId]
      let channel = channels[uniqueId]
      os_log(.info, log: log, "SourceConnectionState(%d '%{public}s' %d", uniqueId, displayName, connected)
      return SourceConnectionState(uniqueId: uniqueId, displayName: displayName, connected: connected,
                                   channel: channel, group: group)
    }
  }

  /// Delegate which will receive incoming MIDI messages
  public weak var receiver: Receiver?

  /// Delegate which will receive notification about MIDI connectivity
  public weak var monitor: Monitor?
  private lazy var eventQueue: DispatchQueue = {
    let name = clientName.isEmpty ? UUID().uuidString : clientName.onlyAlphaNumerics
    let eventQueueName = "\(Bundle.main.bundleIdentifier ?? "com.braysoft.MorkAndMIDI").midi.\(name).events"
    return DispatchQueue(label: eventQueueName, qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem,
                         target: .global(qos: .userInitiated))
  }()

  /**
   Create new instance. Initializes CoreMIDI and creates an input port to receive MIDI traffic.

   - parameter clientName: the name for the MIDI client. This will be visible to in CoreMIDI queries
   - parameter uniqueId: the unique ID to use for the input port of the client
   - parameter midiProto: the Apple MIDI protocol / API to use
   */
  public init(clientName: String, uniqueId: MIDIUniqueID, midiProto: MIDIProto = .v2_0) {
    self.midiProto = midiProto
    self.clientName = clientName
    self.ourUniqueId = uniqueId
    super.init()
  }

  /**
   Tear down MIDI plumbing.
   */
  deinit {
    monitor?.willUninitialize()
  }
}

public extension MIDI {

  /**
   Begin MIDI processing.
   */
  @discardableResult
  func start() -> Bool {
    guard Thread.isMainThread else { fatalError("MIDI must start on the main thread for proper operation.") }
    guard inputPort == MIDIPortRef() else { return false }
    guard createClient() else { return false }
    monitor?.didInitialize()

    guard createInputPort() else { return false }
    initializeInputPort()
    monitor?.didCreate(inputPort: inputPort)

    configureNetworkConnections()
    self.eventQueue.async { [weak self] in
      self?.updateConnections()
    }

    monitor?.didStart()
    return true
  }

  /**
   End MIDI processing.
   */
  func stop() {
    if inputPort != MIDIPortRef() {
      monitor?.willDelete(inputPort: inputPort)
      MIDIPortDispose(inputPort)
        .wasSuccessful(log, "MIDIPortDispose")
      inputPort = MIDIPortRef()

      // NOTE: according to note about MIDIClientDispose this should not be called since it could lave the app without
      // MIDI connectivity. All will be cleaned up upon app exit.
      // MIDIClientDispose(client)
      //  .wasSuccessful(log, "MIDIClientDispose")
    }

    channels.removeAll()
    groups.removeAll()
    activeConnections.removeAll()

    monitor?.didStop()
  }

  /**
   Associate a channel number with the unique ID of a connection endpoint.

   - parameter uniqueId: the uniqueId of the endpoints
   - parameter channel: the channel number
   */
  func updateEndpointInfo(uniqueId: MIDIUniqueID, group: Int, channel: Int) {
    os_log(.debug, log: log, "updateEndpointInfo: %d %d %d", uniqueId, group, channel)
    groups[uniqueId] = group
    channels[uniqueId] = channel
    monitor?.didSee(uniqueId: uniqueId, group: group, channel: channel)
  }

  /**
   Establish a connection to the endpoint with the given unique ID

   - parameter uniqueId: the unique ID of the endpoint
   - returns: true if established
   */
  func connect(to uniqueId: MIDIUniqueID) -> Bool {
    guard let endpoint = KnownSources.matching(uniqueId: uniqueId) else { return false }
    return eventQueue.sync {
      guard self.connectSource(endpoint: endpoint) != nil else { return false }
      self.activeConnections.insert(uniqueId)
      return true
    }
  }

  /**
   Remove a connection from the endpoint with the given unique ID

   - parameter uniqueId: the unique ID of the endpoint
   - returns: true if disconnected
   */
  func disconnect(from uniqueId: MIDIUniqueID) {
    guard KnownSources.matching(uniqueId: uniqueId) != nil else { return }
    eventQueue.sync {
      _ = self.disconnectSource(uniqueId: uniqueId)
      self.activeConnections.remove(uniqueId)
    }
  }
}

internal extension MIDI {

  /**
   Create a virtual output port to use for testing MIDI package delivery and parsing.

   - parameter uniqueId: the unique ID to assign to the output port
   - returns: the MIDIEndpointRef of the new output port
   */
  func createOutputPort(uniqueId: MIDIUniqueID, midiProtocol: MIDIProtocolID = ._2_0) -> MIDIEndpointRef {
    var outputPort: MIDIEndpointRef = .init()
    let outputPortName = clientName + " Output"
    MIDISourceCreateWithProtocol(client, outputPortName as CFString, midiProtocol, &outputPort)
      .wasSuccessful(log, "MIDISourceCreateWithProtocol")
    outputPort.uniqueId = uniqueId
    return outputPort
  }

  /**
   Create a new MIDI client to host all of the MIDI connections.
   */
  func createClient() -> Bool {
    let result = MIDIClientCreateWithBlock(clientName as CFString, &client) { [weak self] notificationPointer in
      guard let self = self else { return }

      let notification = notificationPointer.pointee
      let messageID = notification.messageID
      os_log(.debug, log: self.log, "client callback: %{public}s", messageID.tag)
      if messageID  == .msgSetupChanged {
        self.eventQueue.async {
          self.updateConnections()
        }
      }
    }

    return result.wasSuccessful(log, "MIDIClientCreateWithBlock")
  }

  func createInputPort() -> Bool {
    guard inputPort == MIDIEndpointRef() else { return false }
    let inputPortName = inputPortName as CFString
    let result: OSStatus

    if let midiProtocol = midiProto.midiProtocolId {
      os_log(.debug, log: self.log, "creating input port with protocol %d (event lists)", midiProtocol.rawValue)
      result = MIDIInputPortCreateWithProtocol(client, inputPortName, midiProtocol,
                                               &inputPort) { [weak self] eventListPointer, refCon in
        guard let self = self, let uniqueId = MIDIUniqueID.unbox(refCon) else { return }
        self.processEventList(eventList: eventListPointer, uniqueId: uniqueId)
      }
    } else {
      os_log(.debug, log: self.log, "creating legacy input port (packet lists)")
      result = MIDIInputPortCreateWithBlock(client, inputPortName,
                                            &inputPort) { [weak self] packetListPointer, refCon in
        guard let self = self, let uniqueId = MIDIUniqueID.unbox(refCon) else { return }
        self.processPacketList(packetList: packetListPointer, uniqueId: uniqueId)
      }
    }

    return result.wasSuccessful(log, "MIDIInputPortCreateWithProtocol")
  }
}

private extension MIDI {

  func processPacketList(packetList: UnsafePointer<MIDIPacketList>, uniqueId: MIDIUniqueID) {
    for packet in packetList.unsafeSequence() {
      parser1.parse(source: uniqueId, bytes: MIDIPacket.ByteCollection(packet))
    }
  }

  func processEventList(eventList: UnsafePointer<MIDIEventList>, uniqueId: MIDIUniqueID) {
    eventList.unsafeSequence().forEach { eventPacket in
      parser2.parse(source: uniqueId, words: eventPacket.words())
    }
  }

  func updateConnections() {
    os_log(.info, log: log, "updateConnections")
    monitor?.willUpdateConnections()

    let active = KnownSources.all.filter { $0.uniqueId != ourUniqueId }
    let added = active.compactMap { connectSource(endpoint: $0) }

    let disappeared = activeConnections.subtracting(active.uniqueIds)
    let removed = disappeared.compactMap { disconnectSource(uniqueId: $0) }

    activeConnections.formUnion(added.map { $0.uniqueId })
    activeConnections.subtract(removed.map { $0.uniqueId })

    os_log(.info, log: log, "activeConnections: %{public}s", activeConnections.description)
    monitor?.didUpdateConnections(connected: added, disappeared: disappeared.map { $0 })
  }

  func connectSource(endpoint: MIDIEndpointRef) -> MIDIEndpointRef? {
    let name = endpoint.displayName
    let uniqueId = endpoint.uniqueId
    os_log(.info, log: log, "connectSource - %d '%{public}s' %d", uniqueId, name, endpoint)

    guard uniqueId != ourUniqueId && !activeConnections.contains(uniqueId) else {
      os_log(.debug, log: log, "already connected to endpoint %d '%{public}s'", uniqueId, name)
      return nil
    }

    guard monitor?.shouldConnect(to: uniqueId) ?? true else {
      os_log(.info, log: log, "connectSource - blocked by monitor")
      return nil
    }

    let refCon = uniqueId.boxed
    refCons[uniqueId] = refCon

    os_log(.info, log: log, "connecting endpoint %d '%{public}s' %d %ld", uniqueId, name, endpoint, refCon)
    let success = MIDIPortConnectSource(inputPort, endpoint, refCon)
      .wasSuccessful(log, "MIDIPortConnectSource")
    if success {
      monitor?.didConnect(to: uniqueId)
    }

    return success ? endpoint : nil
  }

  func disconnectSource(uniqueId: MIDIUniqueID) -> MIDIEndpointRef? {
    activeConnections.remove(uniqueId)
    groups.removeValue(forKey: uniqueId)
    channels.removeValue(forKey: uniqueId)

    if let refCon = refCons.removeValue(forKey: uniqueId) {
      refCon.deallocate()
    }

    guard let endpoint = KnownSources.matching(uniqueId: uniqueId) else {
      os_log(.error, log: log, "unable to disconnect - no endpoint with uniqueId %d", uniqueId)
      return nil
    }

    return MIDIPortDisconnectSource(inputPort, endpoint)
      .wasSuccessful(log, "MIDIPortDisconnectSource") ? endpoint : nil
  }

  func initializeInputPort() {
    os_log(.debug, log: log, "initializeInputPort")

    if KnownDestinations.matching(uniqueId: ourUniqueId) == nil {
      ourUniqueId = inputPort.uniqueId
    } else {
      inputPort.uniqueId = ourUniqueId
    }

    inputPort.set(kMIDIPropertyManufacturer, to: manufacturer)
    inputPort.set(kMIDIPropertyModel, to: model)
    inputPort.set(kMIDIPropertyDisplayName, to: inputPort.name)
  }

  func configureNetworkConnections() {
    let mns = MIDINetworkSession.default()
    mns.isEnabled = enableNetworkConnections
    mns.connectionPolicy = enableNetworkConnections ? .anyone : .noOne

    os_log(.debug, log: log, "clientName: %{public}s", clientName)
    os_log(.debug, log: log, "net session enabled: %d", mns.isEnabled)
    os_log(.debug, log: log, "net session networkPort: %d", mns.networkPort)
    os_log(.debug, log: log, "net session networkName: %{public}s", mns.networkName)
    os_log(.debug, log: log, "net session localName: %{public}s", mns.localName)
  }
}
