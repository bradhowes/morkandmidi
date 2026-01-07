// Copyright © 2023-2026 Brad Howes. All rights reserved.

import CoreMIDI

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
  func noteOff(source: MIDIUniqueID, note: UInt8, velocity: UInt8, channel: UInt8)

  /**
   Stop playing a note. (MIDI v2)

   - parameter note: the MIDI note to stop
   - parameter velocity: the velocity to use when stopping the note
   - parameter attributeType: attribute associated with the note (none if 0)
   - parameter attributeData: attribute value
   */
  func noteOff2(source: MIDIUniqueID, note: UInt8, velocity: UInt16, channel: UInt8, attributeType: UInt8, attributeData: UInt16)

  /**
   Start playing a note. (MIDI v1)

   - parameter note: the MIDI note to play
   - parameter velocity: the velocity to use when playing
   */
  func noteOn(source: MIDIUniqueID, note: UInt8, velocity: UInt8, channel: UInt8)

  /**
   Start playing a note. (MIDI v2)
   NOTE: unlike the v1 version, a velocity of 0 does *not* translate to a note off.

   - parameter note: the MIDI note to play
   - parameter velocity: the velocity to use when playing
   - parameter attributeType: attribute associated with the note (none if 0)
   - parameter attributeData: attribute value
   */
  func noteOn2(source: MIDIUniqueID, note: UInt8, velocity: UInt16, channel: UInt8, attributeType: UInt8, attributeData: UInt16)

  /**
   Update the key pressure of a playing note. (MIDI v1)

   - parameter note: the MIDI note that was previous started
   - parameter pressure: the new pressure to use
   */
  func polyphonicKeyPressure(source: MIDIUniqueID, note: UInt8, pressure: UInt8, channel: UInt8)

  /**
   Update the key pressure of a playing note. (MIDI v2)

   - parameter note: the MIDI note that was previous started
   - parameter pressure: the new pressure to use
   */
  func polyphonicKeyPressure2(source: MIDIUniqueID, note: UInt8, pressure: UInt32, channel: UInt8)

  /**
   Change a controller value (MIDI v1)

   - parameter controller: the controller to change
   - parameter value: the value to use
   */
  func controlChange(source: MIDIUniqueID, controller: UInt8, value: UInt8, channel: UInt8)

  /**
   Change a controller value (MIDI v2)

   - parameter controller: the controller to change
   - parameter value: the value to use
   */
  func controlChange2(source: MIDIUniqueID, controller: UInt8, value: UInt32, channel: UInt8)

  /**
   Change the program/preset (0-127) (MIDI v1 *and* MIDI v2 when bank is not used)

   - parameter program: the new program to use
   */
  func programChange(source: MIDIUniqueID, program: UInt8, channel: UInt8)

  /**
   Change the program/preset and bank. (MIDI v2)
   Note that if the MIDI2 message does not contain a valid bank value, this method is not invoked but rather the
   one above with just a program change value.

   - parameter program: the new program to use
   - parameter bank: the new bank to use
   */
  func programChange2(source: MIDIUniqueID, program: UInt8, bank: UInt16, channel: UInt8)

  /**
   Change the whole pressure for the channel. Affects all playing notes. (MIDI v1)

   - parameter pressure: the new pressure to use
   */
  func channelPressure(source: MIDIUniqueID, pressure: UInt8, channel: UInt8)

  /**
   Change the whole pressure for the channel. Affects all playing notes. (MIDI v2)

   - parameter pressure: the new pressure to use
   */
  func channelPressure2(source: MIDIUniqueID, pressure: UInt32, channel: UInt8)

  /**
   Update the pitch-bend controller to a new value. (MIDI v1)

   - parameter value: the new pitch-bend value to use
   */
  func pitchBendChange(source: MIDIUniqueID, value: UInt16, channel: UInt8)

  /**
   Update the pitch-bend controller to a new value. (MIDI v2)

   - parameter value: the new pitch-bend value to use
   */
  func pitchBendChange2(source: MIDIUniqueID, value: UInt32, channel: UInt8)

  /**
   Update the pitch-bend of a specific note. (MIDI v2)

   - parameter note: the MIDI note that to adjust
   - parameter value: the new pitch-bend value to use
   */
  func perNotePitchBendChange(source: MIDIUniqueID, note: UInt8, value: UInt32)

  // MARK: - MIDI v1 and v2 status and utility notifications

  func timeCodeQuarterFrame(source: MIDIUniqueID, value: UInt8)

  func songPositionPointer(source: MIDIUniqueID, value: UInt16)

  func songSelect(source: MIDIUniqueID, value: UInt8)

  func tuneRequest(source: MIDIUniqueID)

  func timingClock(source: MIDIUniqueID)

  func startCurrentSequence(source: MIDIUniqueID)

  func continueCurrentSequence(source: MIDIUniqueID)

  func stopCurrentSequence(source: MIDIUniqueID)

  func activeSensing(source: MIDIUniqueID)

  func systemReset(source: MIDIUniqueID)

  // MARK: - MIDI v2 notifications

  func registeredPerNoteControllerChange(source: MIDIUniqueID, note: UInt8, controller: UInt8, value: UInt32)

  func assignablePerNoteControllerChange(source: MIDIUniqueID, note: UInt8, controller: UInt8, value: UInt32)

  func registeredControllerChange(source: MIDIUniqueID, controller: UInt16, value: UInt32)

  func assignableControllerChange(source: MIDIUniqueID, controller: UInt16, value: UInt32)

  func relativeRegisteredControllerChange(source: MIDIUniqueID, controller: UInt16, value: Int32)

  func relativeAssignableControllerChange(source: MIDIUniqueID, controller: UInt16, value: Int32)

  func perNoteManagement(source: MIDIUniqueID, note: UInt8, detach: Bool, reset: Bool)
}

// MARK: - Default implementations of Receiver protocol

protocol ReceiverWithDefaults: Receiver {}

extension ReceiverWithDefaults {

  var channel: Int { return -1 }
  var group: Int { return -1 }

  func noteOff(source: MIDIUniqueID, note: UInt8, velocity: UInt8, channel: UInt8) {}
  func noteOff2(source: MIDIUniqueID, note: UInt8, velocity: UInt16, channel: UInt8, attributeType: UInt8, attributeData: UInt16) {}
  func noteOn(source: MIDIUniqueID, note: UInt8, velocity: UInt8, channel: UInt8) {}
  func noteOn2(source: MIDIUniqueID, note: UInt8, velocity: UInt16, channel: UInt8, attributeType: UInt8, attributeData: UInt16) {}
  func polyphonicKeyPressure(source: MIDIUniqueID, note: UInt8, pressure: UInt8, channel: UInt8) {}
  func polyphonicKeyPressure2(source: MIDIUniqueID, note: UInt8, pressure: UInt32, channel: UInt8) {}
  func controlChange(source: MIDIUniqueID, controller: UInt8, value: UInt8, channel: UInt8) {}
  func controlChange2(source: MIDIUniqueID, controller: UInt8, value: UInt32, channel: UInt8) {}
  func programChange(source: MIDIUniqueID, program: UInt8, channel: UInt8) {}
  func programChange2(source: MIDIUniqueID, program: UInt8, bank: UInt16, channel: UInt8) {}
  func channelPressure(source: MIDIUniqueID, pressure: UInt8, channel: UInt8) {}
  func channelPressure2(source: MIDIUniqueID, pressure: UInt32, channel: UInt8) {}
  func pitchBendChange(source: MIDIUniqueID, value: UInt16, channel: UInt8) {}
  func pitchBendChange2(source: MIDIUniqueID, value: UInt32, channel: UInt8) {}
  func perNotePitchBendChange(source: MIDIUniqueID, note: UInt8, value: UInt32) {}
  func timeCodeQuarterFrame(source: MIDIUniqueID, value: UInt8) {}
  func songPositionPointer(source: MIDIUniqueID, value: UInt16) {}
  func songSelect(source: MIDIUniqueID, value: UInt8) {}
  func tuneRequest(source: MIDIUniqueID) {}
  func timingClock(source: MIDIUniqueID) {}
  func startCurrentSequence(source: MIDIUniqueID) {}
  func continueCurrentSequence(source: MIDIUniqueID) {}
  func stopCurrentSequence(source: MIDIUniqueID) {}
  func activeSensing(source: MIDIUniqueID) {}
  func systemReset(source: MIDIUniqueID) {}

  func registeredPerNoteControllerChange(source: MIDIUniqueID, note: UInt8, controller: UInt8, value: UInt32) {}

  func assignablePerNoteControllerChange(source: MIDIUniqueID, note: UInt8, controller: UInt8, value: UInt32) {}

  func registeredControllerChange(source: MIDIUniqueID, controller: UInt16, value: UInt32) {}

  func assignableControllerChange(source: MIDIUniqueID, controller: UInt16, value: UInt32) {}

  func relativeRegisteredControllerChange(source: MIDIUniqueID, controller: UInt16, value: Int32) {}

  func relativeAssignableControllerChange(source: MIDIUniqueID, controller: UInt16, value: Int32) {}

  func perNoteManagement(source: MIDIUniqueID, note: UInt8, detach: Bool, reset: Bool) {}
}

// Sentinel to flag if there is a spelling mistake between the protocol and the default implementations.
private class _ReceiverCheck: ReceiverWithDefaults {}
