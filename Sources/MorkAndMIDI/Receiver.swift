// Copyright © 2023 Brad Howes. All rights reserved.

/**
 Protocol for an object that processes supported MIDI messages. All methods of the protocol are optional; each has a
 default implementation that does nothing.

 This protocol handles both MIDI v1 and v2 messages but not any SysEx ones.
 */
public protocol Receiver: AnyObject {

  /// The channel the controller listens on. If -1, then it wants msgs from ALL channels
  var channel: Int { get }

  /// For MIDI v2 group that can be used to filter incoming messages. If -1, then the group value in the MIDI v2
  /// message is ignored (the message will not be filtered by group ID)
  var group: Int { get }

  /**
   Stop playing a note. (MIDI v1)

   - parameter note: the MIDI note to stop
   - parameter velocity: the velocity to use when stopping the note
   */
  func noteOff(note: UInt8, velocity: UInt8)

  /**
   Stop playing a note. (MIDI v2)

   - parameter note: the MIDI note to stop
   - parameter velocity: the velocity to use when stopping the note
   - parameter attributeType: attribute associated with the note (none if 0)
   - parameter attributeData: attribute value
   */
  func noteOff2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16)

  /**
   Start playing a note. (MIDI v1)

   - parameter note: the MIDI note to play
   - parameter velocity: the velocity to use when playing
   */
  func noteOn(note: UInt8, velocity: UInt8)

  /**
   Start playing a note. (MIDI v2)
   NOTE: unlike the v1 version, a velocity of 0 does *not* translate to a note off.

   - parameter note: the MIDI note to play
   - parameter velocity: the velocity to use when playing
   - parameter attributeType: attribute associated with the note (none if 0)
   - parameter attributeData: attribute value
   */
  func noteOn2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16)

  /**
   Command the keyboard to release any pressed keys
   */
  func allNotesOff()

  /**
   Update the key pressure of a playing note. (MIDI v1)

   - parameter note: the MIDI note that was previous started
   - parameter pressure: the new pressure to use
   */
  func polyphonicKeyPressure(note: UInt8, pressure: UInt8)

  /**
   Update the key pressure of a playing note. (MIDI v2)

   - parameter note: the MIDI note that was previous started
   - parameter pressure: the new pressure to use
   */
  func polyphonicKeyPressure2(note: UInt8, pressure: UInt32)

  /**
   Change a controller value (MIDI v1)

   - parameter controller: the controller to change
   - parameter value: the value to use
   */
  func controlChange(controller: UInt8, value: UInt8)

  /**
   Change a controller value (MIDI v2)

   - parameter controller: the controller to change
   - parameter value: the value to use
   */
  func controlChange2(controller: UInt8, value: UInt32)

  /**
   Change the program/preset (0-127) (MIDI v1 *and* MIDI v2 when bank is not used)

   - parameter program: the new program to use
   */
  func programChange(program: UInt8)

  /**
   Change the program/preset and bank. (MIDI v2)
   Note that if the MIDI2 message does not contain a valid bank value, this method is not invoked but rather the
   one above with just a program change value.

   - parameter program: the new program to use
   - parameter bank: the new bank to use
   */
  func programChange2(program: UInt8, bank: UInt16)

  /**
   Change the whole pressure for the channel. Affects all playing notes. (MIDI v1)

   - parameter pressure: the new pressure to use
   */
  func channelPressure(pressure: UInt8)

  /**
   Change the whole pressure for the channel. Affects all playing notes. (MIDI v2)

   - parameter pressure: the new pressure to use
   */
  func channelPressure2(pressure: UInt32)

  /**
   Update the pitch-bend controller to a new value. (MIDI v1)

   - parameter value: the new pitch-bend value to use
   */
  func pitchBendChange(value: UInt16)

  /**
   Update the pitch-bend controller to a new value. (MIDI v2)

   - parameter value: the new pitch-bend value to use
   */
  func pitchBendChange2(value: UInt32)

  /**
   Update the pitch-bend of a specific note. (MIDI v2)

   - parameter note: the MIDI note that to adjust
   - parameter value: the new pitch-bend value to use
   */
  func pitchBendChangePerNote(note: UInt8, value: UInt32)

  // MARK: - MIDI v1 and v2 status and utility notifications

  func timeCodeQuarterFrame(value: UInt8)

  func songPositionPointer(value: UInt16)

  func songSelect(value: UInt8)

  func tuneRequest()

  func timingClock()

  func startCurrentSequence()

  func continueCurrentSequence()

  func stopCurrentSequence()

  func activeSensing()

  func reset()

  // MARK: - MIDI v2 notifications

  func registeredPerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32)

  func assignablePerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32)

  func registeredControllerChange(controller: UInt16, value: UInt32)

  func assignableControllerChange(controller: UInt16, value: UInt32)

  func relativeRegisteredControllerChange(controller: UInt16, value: Int32)

  func relativeAssignableControllerChange(controller: UInt16, value: Int32)

  func perNoteManagement(note: UInt8, detach: Bool, reset: Bool)
}

// MARK: - Default implementations of Receiver protocol

public extension Receiver {

  var channel: Int { return -1 }
  var group: Int { return -1 }

  func noteOff(note: UInt8, velocity: UInt8) {}
  func noteOff2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {}
  func noteOn(note: UInt8, velocity: UInt8) {}
  func noteOn2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {}
  func allNotesOff() {}
  func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {}
  func polyphonicKeyPressure2(note: UInt8, pressure: UInt32) {}
  func controlChange(controller: UInt8, value: UInt8) {}
  func controlChange2(controller: UInt8, value: UInt32) {}
  func programChange(program: UInt8) {}
  func programChange2(program: UInt8, bank: UInt16) {}
  func channelPressure(pressure: UInt8) {}
  func channelPressure2(pressure: UInt32) {}
  func pitchBendChange(value: UInt16) {}
  func pitchBendChange2(value: UInt32) {}
  func pitchBendChangePerNote(note: UInt8, value: UInt32) {}
  func timeCodeQuarterFrame(value: UInt8) {}
  func songPositionPointer(value: UInt16) {}
  func songSelect(value: UInt8) {}
  func tuneRequest() {}
  func timingClock() {}
  func startCurrentSequence() {}
  func continueCurrentSequence() {}
  func stopCurrentSequence() {}
  func activeSensing() {}
  func reset() { allNotesOff() }

  func registeredPerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32) {}

  func assignablePerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32) {}

  func registeredControllerChange(controller: UInt16, value: UInt32) {}

  func assignableControllerChange(controller: UInt16, value: UInt32) {}

  func relativeRegisteredControllerChange(controller: UInt16, value: Int32) {}

  func relativeAssignableControllerChange(controller: UInt16, value: Int32) {}

  func perNoteManagement(note: UInt8, detach: Bool, reset: Bool) {}
}

// Sentinel to flag if there is a spelling mistake between the protocol and the default implementations.
private class _ReceiverCheck: Receiver {}

