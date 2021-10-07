// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MIDITests: XCTestCase {

  var midi: MIDI!
  var monitor: Monitor!

  override func setUp() {
    midi = MIDI(clientName: "foo", uniqueId: 12_345)
    monitor = Monitor(self)
    midi.monitor = monitor
  }

  override func tearDown() {
    midi.makeInactive()
    midi = nil
    monitor = nil
  }

  func setMonitorExpectation(_ kind: Monitor.ExpectationKind) {
    monitor.setExpectation(kind)
    midi.start()
    waitForExpectations(timeout: 15.0)
  }

  func testCreation() {
    XCTAssertNil(MIDI.activeInstance)
    midi.start();
    XCTAssertEqual(midi, MIDI.activeInstance)
    MIDI.activeInstance?.makeInactive()
    XCTAssertNil(MIDI.activeInstance)
  }

  func testStartup() {
    setMonitorExpectation(.initialized)
  }

  func testUpdatedDevices() {
    setMonitorExpectation(.updatedDevices)
    XCTAssertEqual(midi.devices.count, 1)
  }

  func testUpdatedConnections() {
    setMonitorExpectation(.updatedConnections)
    XCTAssertEqual(midi.activeConnections.count, 1)
  }
}
