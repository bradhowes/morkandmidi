// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI

/**
 Protocol for an object that monitors MIDI input activity
 */
public protocol Monitor: AnyObject {

  /**
   Notification that the MIDI system is initialized and ready to receive messages

   - parameter uniqueId: the unique ID of the virtual MIDI endpoint that will receive incoming messages
   */
  func initialized(uniqueId: MIDIUniqueID)

  /**
   Notification that the known devices has changed
   */
  func updatedDevices()

  /**
   Notification that active connections have changed
   */
  func updatedConnections()

  /**
   Notification invoked when there is an incoming MIDI message.

   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the message
   - parameter channel: the channel found in the MIDI message
   */
  func seen(uniqueId: MIDIUniqueID, channel: Int)
}

extension Monitor {

  public func initialized(uniqueId: MIDIUniqueID) {}

  public func updatedDevices() {}

  public func updatedConnections() {}

  public func seen(uniqueId: MIDIUniqueID, channel: Int) {}
}
