// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SimplyMIDI
import CoreMIDI
import XCTest

class MIDITests: XCTestCase {

  func testCreation() {
    XCTAssertNil(SimplyMIDI.MIDI.activeInstance)
    do {
      let midi = SimplyMIDI.MIDI(clientName: "foo", uniqueId: 12_345)
      XCTAssertEqual(midi, SimplyMIDI.MIDI.activeInstance)
    }

    SimplyMIDI.MIDI.activeInstance?.release()
    XCTAssertNil(SimplyMIDI.MIDI.activeInstance)
  }

  func testStartup() {
    let mm1 = Monitor()
    mm1.initializedExpectation = self.expectation(description: "m1 initialized")
    let m1 = SimplyMIDI.MIDI(clientName: "foo", uniqueId: 12_345)
    m1.monitor = mm1
    waitForExpectations(timeout: 5.0)
  }

  func testUpdatedDevices() {
    let mm1 = Monitor()
    mm1.updatedDevicesExpectation = self.expectation(description: "m1 updatedDevices")
    let m1 = SimplyMIDI.MIDI(clientName: "foo", uniqueId: 12_345)
    m1.monitor = mm1
    waitForExpectations(timeout: 5.0)
    XCTAssertEqual(m1.devices.count, 1)
  }

  func testUpdatedConnections() {
    let mm1 = Monitor()
    mm1.updatedConnectionsExpectation = self.expectation(description: "m1 updatedConnections")
    let m1 = SimplyMIDI.MIDI(clientName: "foo", uniqueId: 12_345)
    m1.monitor = mm1
    waitForExpectations(timeout: 5.0)
    XCTAssertEqual(m1.activeConnections.count, 1)
  }
}
