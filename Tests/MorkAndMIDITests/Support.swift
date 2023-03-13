// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

internal class Receiver: MorkAndMIDI.Receiver {

  struct Event: Equatable {
    let cmd: UInt8
    let data1: UInt8
    let data2: UInt8
  }

  var channel: Int = -1
  var received = [Event]()

  func noteOn(note: UInt8, velocity: UInt8) { self.received.append(Event(cmd: 0x90, data1: note, data2: velocity)) }
  func noteOff(note: UInt8, velocity: UInt8) { self.received.append(Event(cmd: 0x80, data1: note, data2: velocity)) }
  func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {
    self.received.append(Event(cmd: 0xA0, data1: note, data2: pressure))
  }
  func controlChange(controller: UInt8, value: UInt8) {
    self.received.append(Event(cmd: 0xB0, data1: controller, data2: value))
  }
  func programChange(program: UInt8) {
    self.received.append(Event(cmd: 0xC0, data1: program, data2: 0))
  }
  func channelPressure(pressure: UInt8) {
    self.received.append(Event(cmd: 0xD0, data1: pressure, data2: 0))
  }
  func pitchBendChange(value: UInt16) {
    self.received.append(Event(cmd: 0xE0, data1: UInt8(value >> 7), data2: UInt8(value & 0x7F)))
  }
  func timeCodeQuarterFrame(value: UInt8) {
    self.received.append(Event(cmd: 0xF1, data1: value, data2: 0))
  }
  func songPositionPointer(value: UInt16) {
    self.received.append(Event(cmd: 0xF2, data1: UInt8(value >> 7), data2: UInt8(value & 0x7F)))
  }
  func songSelect(value: UInt8) {
    self.received.append(Event(cmd: 0xF3, data1: value, data2: 0))
  }
  func tuneRequest() {
    self.received.append(Event(cmd: 0xF6, data1: 0, data2: 0))
  }
  func timingClock() {
    self.received.append(Event(cmd: 0xF8, data1: 0, data2: 0))
  }
  func startCurrentSequence() {
    self.received.append(Event(cmd: 0xFA, data1: 0, data2: 0))
  }
  func continueCurrentSequence() {
    self.received.append(Event(cmd: 0xFB, data1: 0, data2: 0))
  }
  func stopCurrentSequence() {
    self.received.append(Event(cmd: 0xFC, data1: 0, data2: 0))
  }
  func activeSensing() {
    self.received.append(Event(cmd: 0xFE, data1: 0, data2: 0))
  }
  func allNotesOff() {
    self.received.append(Event(cmd: 0xFF, data1: 0, data2: 0))
  }
}

internal class Monitor: MorkAndMIDI.Monitor {

  enum ExpectationKind: String {
    case initialized
    case deinitialized
    case updatedDevices
    case updatedConnections
    case seen
  }

  weak var test: XCTestCase?
  var uniqueIds = [MIDIUniqueID: Int]()
  var ourUniqueId: MIDIUniqueID?
  var expectationKind: ExpectationKind!
  var expectation: XCTestExpectation!

  init(_ test: XCTestCase) {
    self.test = test
  }

  func fulfill(_ kind: ExpectationKind) {
    guard expectation != nil else { return }
    print("fulfill: ", kind.rawValue, expectationKind.rawValue)
    if kind == expectationKind {
      expectation.fulfill()
    }
  }

  func setExpectation(_ kind: ExpectationKind) {
    self.expectationKind = kind
    self.expectation = test?.expectation(description: kind.rawValue)
  }

  func initialized(uniqueId: MIDIUniqueID) {
    ourUniqueId = uniqueId
    fulfill(.initialized)
  }

  func deinitialized() { fulfill(.deinitialized) }
  func updatedDevices() { fulfill(.updatedDevices) }
  func updatedConnections() { fulfill(.updatedConnections) }

 func seen(uniqueId: MIDIUniqueID, channel: Int) {
   uniqueIds[uniqueId] = channel
   fulfill(.seen)
  }
}
