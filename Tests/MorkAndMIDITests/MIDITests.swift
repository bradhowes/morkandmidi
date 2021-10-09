// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MIDITests: XCTestCase {

  var midi: MIDI!
  var monitor: Monitor!

  override func setUp() {
    super.setUp()
    midi = MIDI(clientName: "foo", uniqueId: 12_345)
    monitor = Monitor(self)
    midi.monitor = monitor
  }

  override func tearDown() {
    midi?.stop()
    midi = nil
    monitor = nil
    super.tearDown()
  }

  func setMonitorExpectation(_ kind: Monitor.ExpectationKind) {
    monitor.setExpectation(kind)
    midi.start()
    waitForExpectations(timeout: 15.0)
  }

  func testDeinitialized() {
    monitor.setExpectation(.deinitialized)
    midi.start()
    midi.stop()
    midi = nil
    waitForExpectations(timeout: 15.0)
  }

  func testStartup() {
    setMonitorExpectation(.initialized)
  }

  func flaky_testUpdatedDevices() {
    setMonitorExpectation(.updatedDevices)
    // XCTAssertEqual(midi.devices.count, 1)
  }

  func flaky_testUpdatedConnections() {
    setMonitorExpectation(.updatedConnections)
    // XCTAssertEqual(midi.activeConnections.count, 1)
  }
}
