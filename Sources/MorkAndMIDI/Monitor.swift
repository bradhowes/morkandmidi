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
   Notification that the MIDI instance started up.
   */
  func didStart()

  /**
   Notification that the MIDI instance stopped.
   */
  func didStop()

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

   - parameter connected: collection of endpoints that were newly connected
   - parameter disappeared: collection of unique IDs that no longer exist as sources
   */
  func didUpdateConnections(connected: any Sequence<MIDIEndpointRef>, disappeared: any Sequence<MIDIUniqueID>)

  /**
   Notification invoked when there is an incoming MIDI message.

   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the message
   - parameter group: the MIDI v2. group found in the MIDI message
   - parameter channel: the channel found in the MIDI message
   */
  func didSee(uniqueId: MIDIUniqueID, group: Int, channel: Int)
}

public protocol MonitorWithDefaults: Monitor {}

/// Default implementations of the Monitor protocol
public extension MonitorWithDefaults {
  
  func didInitialize(uniqueId: MIDIUniqueID) {}
  
  func willUninitialize() {}
  
  func didCreate(inputPort: MIDIPortRef) {}
  
  func willDelete(inputPort: MIDIPortRef) {}

  func didStart() {}

  func didStop() {}
  
  func shouldConnect(to endpoint: MIDIEndpointRef) -> Bool { true }
  
  func didConnect(to endpoint: MIDIEndpointRef) {}
  
  func willUpdateConnections() {}
  
  func didUpdateConnections(connected: any Sequence<MIDIEndpointRef>, disappeared: any Sequence<MIDIUniqueID>) {}

  func didSee(uniqueId: MIDIUniqueID, group: Int, channel: Int) {}
}

// Sentinel to flag if there is a spelling mistake between the protocol and the default implementations.
private class _MonitorCheck: MonitorWithDefaults {}
