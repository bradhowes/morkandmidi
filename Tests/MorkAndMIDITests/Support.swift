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
  var uniqueIds = [MIDIUniqueID: Int]()
  var ourUniqueId: MIDIUniqueID?

  var initializedExpectation: XCTestExpectation?
  var updatedDevicesExpectation: XCTestExpectation?
  var updatedConnectionsExpectation: XCTestExpectation?

  func initialized(uniqueId: MIDIUniqueID) {
    ourUniqueId = uniqueId
    initializedExpectation?.fulfill()
  }

  func updatedDevices() {
    updatedDevicesExpectation?.fulfill()
  }

  func updatedConnections() {
    updatedConnectionsExpectation?.fulfill()
  }

 func seen(uniqueId: MIDIUniqueID, channel: Int) {
    uniqueIds[uniqueId] = channel
  }
}