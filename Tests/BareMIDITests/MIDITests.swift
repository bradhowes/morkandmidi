// Copyright © 2020 Brad Howes. All rights reserved.

@testable import BareMIDI
import CoreMIDI
import XCTest

class MIDITests: XCTestCase {

  func testCreation() {
    XCTAssertNil(MIDI.activeInstance)
    do {
      let midi = MIDI(clientName: "foo", uniqueId: 12_345)
      XCTAssertEqual(midi, BareMIDI.MIDI.activeInstance)
    }

    MIDI.activeInstance?.release()
    XCTAssertNil(MIDI.activeInstance)
  }

  func testStartup() {
    let mm1 = Monitor()
    mm1.initializedExpectation = self.expectation(description: "m1 initialized")
    let m1 = MIDI(clientName: "foo", uniqueId: 12_345)
    m1.monitor = mm1
    waitForExpectations(timeout: 5.0)
  }

  func testUpdatedDevices() {
    let mm1 = Monitor()
    mm1.updatedDevicesExpectation = self.expectation(description: "m1 updatedDevices")
    let m1 = MIDI(clientName: "foo", uniqueId: 12_345)
    m1.monitor = mm1
    waitForExpectations(timeout: 5.0)
    XCTAssertEqual(m1.devices.count, 1)
  }

  func testUpdatedConnections() {
    let mm1 = Monitor()
    mm1.updatedConnectionsExpectation = self.expectation(description: "m1 updatedConnections")
    let m1 = MIDI(clientName: "foo", uniqueId: 12_345)
    m1.monitor = mm1
    waitForExpectations(timeout: 5.0)
    XCTAssertEqual(m1.activeConnections.count, 1)
  }
}
