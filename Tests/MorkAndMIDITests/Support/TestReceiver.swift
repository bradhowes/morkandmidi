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

  func noteOff(note: UInt8, velocity: UInt8) {
    received.append("noteOff \(note) \(velocity)")
    fulfill(.noteOff)
  }
  func noteOff2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    received.append("noteOff2 \(note) \(velocity) \(attributeType) \(attributeData)")
    fulfill(.noteOff)
  }
  func noteOn(note: UInt8, velocity: UInt8) {
    received.append("noteOn \(note) \(velocity)")
    fulfill(.noteOn)
  }
  func noteOn2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    received.append("noteOn2 \(note) \(velocity) \(attributeType) \(attributeData)")
    fulfill(.noteOn)
  }
  func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {
    received.append("polyphonicKeyPressure \(note) \(pressure)")
  }
  func polyphonicKeyPressure2(note: UInt8, pressure: UInt32) {
    received.append("polyphonicKeyPressure2 \(note) \(pressure)")
  }
  func controlChange(controller: UInt8, value: UInt8) {
    received.append("controlChange \(controller) \(value)")
  }
  func controlChange2(controller: UInt8, value: UInt32) {
    received.append("controlChange2 \(controller) \(value)")
  }
  func programChange(program: UInt8) {
    received.append("programChange \(program)")
  }
  func programChange2(program: UInt8, bank: UInt16) {
    received.append("programChange2 \(program) \(bank)")
  }
  func channelPressure(pressure: UInt8) {
    received.append("channelPressure \(pressure)")
  }
  func channelPressure2(pressure: UInt32) {
    received.append("channelPressure2 \(pressure)")
  }
  func pitchBendChange(value: UInt16) {
    received.append("pitchBendChange \(value)")
  }
  func pitchBendChange2(value: UInt32) {
    received.append("pitchBendChange2 \(value)")
  }
  func timeCodeQuarterFrame(value: UInt8) {
    received.append("timeCodeQuarterFrame \(value)")
  }
  func songPositionPointer(value: UInt16) {
    received.append("songPositionPointer \(value)")
  }
  func songSelect(value: UInt8) {
    received.append("songSelect \(value)")
  }
  func tuneRequest() {
    received.append("tuneRequest")
  }
  func timingClock() {
    received.append("timingClock")
  }
  func startCurrentSequence() {
    received.append("startCurrentSequence")
  }
  func continueCurrentSequence() {
    received.append("continueCurrentSequence")
  }
  func stopCurrentSequence() {
    received.append("stopCurrentSequence")
  }
  func activeSensing() {
    received.append("activeSensing")
  }
  func systemReset() {
    received.append("systemReset")
  }
  func registeredPerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32) {
    received.append("registeredPerNoteControllerChange \(note) \(controller) \(value)")
  }
  func assignablePerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32) {
    received.append("assignablePerNoteControllerChange \(note) \(controller) \(value)")
  }
  func registeredControllerChange(controller: UInt16, value: UInt32) {
    received.append("registeredControllerChange \(controller) \(value)")
  }
  func assignableControllerChange(controller: UInt16, value: UInt32) {
    received.append("assignableControllerChange \(controller) \(value)")
  }
  func relativeRegisteredControllerChange(controller: UInt16, value: Int32) {
    received.append("relativeRegisteredControllerChange \(controller) \(value)")
  }
  func relativeAssignableControllerChange(controller: UInt16, value: Int32) {
    received.append("relativeAssignableControllerChange \(controller) \(value)")
  }
  func perNoteManagement(note: UInt8, detach: Bool, reset: Bool) {
    received.append("perNoteManagement \(note) \(detach) \(reset)")
  }
  func perNotePitchBendChange(note: UInt8, value: UInt32) {
    received.append("perNotePitchBendChange \(note) \(value)")
  }
}
