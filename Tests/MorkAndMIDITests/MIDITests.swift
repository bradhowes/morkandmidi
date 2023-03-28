// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

#if os(macOS)
class MIDITests: MonitoredTestCase {

  override func setUp() {
    super.setUp()
    initialize(clientName: "foo", uniqueId: 12_345)
  }

  override func tearDown() {
    midi?.stop()
    midi = nil
    monitor = nil
    super.tearDown()
  }

  func testPreStartInitialState() {
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
    XCTAssertTrue(midi.activeConnections.isEmpty)
    XCTAssertFalse(midi.isRunning)
    XCTAssertEqual(midi.model, "")
    XCTAssertEqual(midi.manufacturer, "")
    XCTAssertTrue(midi.enableNetworkConnections)
  }

  func testPostStartInitialState() {
    XCTAssertTrue(midi.start())
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
    XCTAssertTrue(midi.isRunning)
  }

  func testStartTwiceFails() {
    XCTAssertTrue(midi.start())
    XCTAssertFalse(midi.start())
  }

  func testStartStopStartSucceeds() {
    XCTAssertTrue(midi.start())
    midi.stop()
    XCTAssertTrue(midi.start())
  }

  func testManufactureProperty() {
    midi.start()
    midi.manufacturer = "B-Ray Software"
    XCTAssertEqual(midi.manufacturer, "B-Ray Software")
    XCTAssertEqual(midi.inputPort.manufacturer, midi.manufacturer)
  }

  func testModelProperty() {
    midi.start()
    midi.model = "SoundFonts"
    XCTAssertEqual(midi.model, "SoundFonts")
    XCTAssertEqual(midi.inputPort.model, midi.model)
  }

  func testEnableNetworkConnections() {
    let mns = MIDINetworkSession.default()
    midi.start()
    // As a package, this test has no effect on MIDINetworkSession.
    midi.enableNetworkConnections = true
    XCTAssertEqual(mns.connectionPolicy, .noOne)
    midi.enableNetworkConnections = false
    XCTAssertEqual(mns.connectionPolicy, .noOne)

  }

  func testStopResetsState() {
    doAndWaitFor(expectation: .didUpdateConnections) {
      self.createSource1()
      self.createSource2()
    }

    let outputUniqueId: MIDIUniqueID = 998877
    let outputPort = doAndWaitFor(expectation: .didConnectTo(uniqueId: outputUniqueId)) {
      self.midi.createOutputPort(uniqueId: outputUniqueId)
    }

    while !midi.activeConnections.contains(outputUniqueId) {
      delay(sec: 0.1)
    }

    XCTAssertTrue(midi.activeConnections.contains(outputUniqueId))

    let packetBuilder = MIDIEventList.Builder(inProtocol: ._2_0,
                                              wordSize: MemoryLayout<MIDIEventList>.size / MemoryLayout<UInt32>.stride)
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_91_60_7F)])
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_81_60_00)])

    doAndWaitFor(expectation: .didSee(uniqueId: outputUniqueId), duration: 10.0) {
      self.monitor.expectation.expectedFulfillmentCount = packetBuilder.count
      _ = packetBuilder.withUnsafePointer {
        MIDIReceivedEventList(outputPort!, $0)
      }
    }

    XCTAssertFalse(midi.channels.isEmpty)
    XCTAssertFalse(midi.groups.isEmpty)

    midi.stop()

    XCTAssertTrue(midi.activeConnections.isEmpty)
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
  }

  func testDisconnectWhenSourceGoesAway() {
    doAndWaitFor(expectation: .didUpdateConnections) {
      self.createSource1()
      self.createSource2()
    }

    let outputUniqueId: MIDIUniqueID = 12347
    while !midi.activeConnections.contains(outputUniqueId) {
      delay(sec: 0.1)
    }

    XCTAssertTrue(midi.activeConnections.contains(outputUniqueId))

    MIDIEndpointDispose(source2)

    while midi.activeConnections.contains(outputUniqueId) {
      delay(sec: 0.1)
    }

    MIDIEndpointDispose(source1)

    while midi.activeConnections.contains(12346) {
      delay(sec: 0.1)
    }

    midi.stop()

    XCTAssertTrue(midi.activeConnections.isEmpty)
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
  }
}

#endif
