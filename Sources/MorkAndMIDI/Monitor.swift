// Copyright © 2023 Brad Howes. All rights reserved.

import CoreMIDI

/**
 Protocol for an object that monitors MIDI input activity
 */
public protocol Monitor: AnyObject {

  /**
   Notification that the MIDI system is initialized and ready to receive messages

   - parameter uniqueId: the unique ID of the virtual MIDI endpoint that will receive incoming messages
   */
  func didInitialize(uniqueId: MIDIUniqueID)

  /**
   Notification that the MIDI system has been torn down.
   */
  func willUninitialize()

  /**
   Notification that an MIDI input port has been created.

   - parameter inputPort: the MIDI input port that will be used for all connections
   */
  func didCreate(inputPort: MIDIPortRef)

  /**
   Notification that the existing MIDI input port will be disposed of

   - parameter inputPort: the MIDI input port
   */
  func willDelete(inputPort: MIDIPortRef)

  /**
   Check if the given endpoint should be connected to or not.

   - parameter endpoint: the source endpoint being queried
   - returns: true if the connection should be established
   */
  func shouldConnect(to endpoint: MIDIEndpointRef) -> Bool

  /**
   Notification that a given endpoint was connected to

   - parameter endpoint: the source endpoint of the connection
   */
  func didConnect(to endpoint: MIDIEndpointRef)

  /**
   Notification that active connections will be updated
   */
  func willUpdateConnections()

  /**
   Notification that active connections were updated.

   - parameter added: collection of endpoints that were newly connected
   - parameter removed: collection of endpoints that were newly disconnected
   */
  func didUpdateConnections(added: [MIDIEndpointRef], removed: [MIDIEndpointRef])

  /**
   Notification invoked when there is an incoming MIDI message.

   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the message
   - parameter group: the MIDI v2. group found in the MIDI message
   - parameter channel: the channel found in the MIDI message
   */
  func didSee(uniqueId: MIDIUniqueID, group: Int, channel: Int)
}

/// Default implementations of the Monitor protocol
extension Monitor {

  public func didInitialize(uniqueId: MIDIUniqueID) {}

  public func willUninitialize() {}

  public func didCreate(inputPort: MIDIPortRef) {}

  public func willDelete(inputPort: MIDIPortRef) {}

  public func shouldConnect(to endpoint: MIDIEndpointRef) -> Bool { true }

  public func didConnect(to endpoint: MIDIEndpointRef) {}

  public func willUpdateConnections() {}

  public func didUpdateConnections(added: [MIDIEndpointRef], removed: [MIDIEndpointRef]) {}

  public func didSee(uniqueId: MIDIUniqueID, group: Int, channel: Int) {}
}

// Sentinel to flag if there is a spelling mistake between the protocol and the default implementations.
private class _MonitorCheck: Monitor {}
