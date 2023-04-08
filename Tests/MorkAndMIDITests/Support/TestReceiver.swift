// Copyright © 2021 Brad Howes. All rights reserved.
import os
@testable import MorkAndMIDI
import CoreMIDI
import XCTest

internal class TestReceiver: Receiver {

  typealias Fulfiller = () -> Void

  enum ExpectationKind: String {
    case noteOff
    case noteOn
  }

  var channel: Int = -1
  var group: Int = -1
  var received = [String]()

  let expected: ExpectationKind?
  let fulfiller: Fulfiller?

  init() {
    self.expected = nil
    self.fulfiller = nil
  }

  init(expected: ExpectationKind, fulfiller: @escaping Fulfiller) {
    self.expected = expected
    self.fulfiller = fulfiller
  }

  func fulfill(_ kind: ExpectationKind) { if kind == expected { fulfiller?() } }

  func noteOff(source: MIDIUniqueID, note: UInt8, velocity: UInt8) {
    received.append("noteOff \(note) \(velocity)")
    fulfill(.noteOff)
  }
  func noteOff2(source: MIDIUniqueID, note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    received.append("noteOff2 \(note) \(velocity) \(attributeType) \(attributeData)")
    fulfill(.noteOff)
  }
  func noteOn(source: MIDIUniqueID, note: UInt8, velocity: UInt8) {
    received.append("noteOn \(note) \(velocity)")
    fulfill(.noteOn)
  }
  func noteOn2(source: MIDIUniqueID, note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    received.append("noteOn2 \(note) \(velocity) \(attributeType) \(attributeData)")
    fulfill(.noteOn)
  }
  func polyphonicKeyPressure(source: MIDIUniqueID, note: UInt8, pressure: UInt8) {
    received.append("polyphonicKeyPressure \(note) \(pressure)")
  }
  func polyphonicKeyPressure2(source: MIDIUniqueID, note: UInt8, pressure: UInt32) {
    received.append("polyphonicKeyPressure2 \(note) \(pressure)")
  }
  func controlChange(source: MIDIUniqueID, controller: UInt8, value: UInt8) {
    received.append("controlChange \(controller) \(value)")
  }
  func controlChange2(source: MIDIUniqueID, controller: UInt8, value: UInt32) {
    received.append("controlChange2 \(controller) \(value)")
  }
  func programChange(source: MIDIUniqueID, program: UInt8) {
    received.append("programChange \(program)")
  }
  func programChange2(source: MIDIUniqueID, program: UInt8, bank: UInt16) {
    received.append("programChange2 \(program) \(bank)")
  }
  func channelPressure(source: MIDIUniqueID, pressure: UInt8) {
    received.append("channelPressure \(pressure)")
  }
  func channelPressure2(source: MIDIUniqueID, pressure: UInt32) {
    received.append("channelPressure2 \(pressure)")
  }
  func pitchBendChange(source: MIDIUniqueID, value: UInt16) {
    received.append("pitchBendChange \(value)")
  }
  func pitchBendChange2(source: MIDIUniqueID, value: UInt32) {
    received.append("pitchBendChange2 \(value)")
  }
  func timeCodeQuarterFrame(source: MIDIUniqueID, value: UInt8) {
    received.append("timeCodeQuarterFrame \(value)")
  }
  func songPositionPointer(source: MIDIUniqueID, value: UInt16) {
    received.append("songPositionPointer \(value)")
  }
  func songSelect(source: MIDIUniqueID, value: UInt8) {
    received.append("songSelect \(value)")
  }
  func tuneRequest(source: MIDIUniqueID) {
    received.append("tuneRequest")
  }
  func timingClock(source: MIDIUniqueID) {
    received.append("timingClock")
  }
  func startCurrentSequence(source: MIDIUniqueID) {
    received.append("startCurrentSequence")
  }
  func continueCurrentSequence(source: MIDIUniqueID) {
    received.append("continueCurrentSequence")
  }
  func stopCurrentSequence(source: MIDIUniqueID) {
    received.append("stopCurrentSequence")
  }
  func activeSensing(source: MIDIUniqueID) {
    received.append("activeSensing")
  }
  func systemReset(source: MIDIUniqueID) {
    received.append("systemReset")
  }
  func registeredPerNoteControllerChange(source: MIDIUniqueID, note: UInt8, controller: UInt8, value: UInt32) {
    received.append("registeredPerNoteControllerChange \(note) \(controller) \(value)")
  }
  func assignablePerNoteControllerChange(source: MIDIUniqueID, note: UInt8, controller: UInt8, value: UInt32) {
    received.append("assignablePerNoteControllerChange \(note) \(controller) \(value)")
  }
  func registeredControllerChange(source: MIDIUniqueID, controller: UInt16, value: UInt32) {
    received.append("registeredControllerChange \(controller) \(value)")
  }
  func assignableControllerChange(source: MIDIUniqueID, controller: UInt16, value: UInt32) {
    received.append("assignableControllerChange \(controller) \(value)")
  }
  func relativeRegisteredControllerChange(source: MIDIUniqueID, controller: UInt16, value: Int32) {
    received.append("relativeRegisteredControllerChange \(controller) \(value)")
  }
  func relativeAssignableControllerChange(source: MIDIUniqueID, controller: UInt16, value: Int32) {
    received.append("relativeAssignableControllerChange \(controller) \(value)")
  }
  func perNoteManagement(source: MIDIUniqueID, note: UInt8, detach: Bool, reset: Bool) {
    received.append("perNoteManagement \(note) \(detach) \(reset)")
  }
  func perNotePitchBendChange(source: MIDIUniqueID, note: UInt8, value: UInt32) {
    received.append("perNotePitchBendChange \(note) \(value)")
  }
}
