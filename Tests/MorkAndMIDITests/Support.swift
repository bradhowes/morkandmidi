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
}

internal class Monitor: MorkAndMIDI.Monitor {

  enum ExpectationKind: String {
    case initialized
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

  func updatedDevices() { fulfill(.updatedDevices) }
  func updatedConnections() { fulfill(.updatedConnections) }

 func seen(uniqueId: MIDIUniqueID, channel: Int) {
   uniqueIds[uniqueId] = channel
   fulfill(.seen)
  }
}
