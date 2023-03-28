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
    doAndWaitFor(expectation: .didCreateInputPort) {}
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
    XCTAssertTrue(midi.isRunning)
  }

  func testStartStopStartSucceeds() {
    doAndWaitFor(expectation: .didCreateInputPort) {}
    doAndWaitFor(expectation: .didStop) { self.midi.stop() }
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
    let outputUniqueId: MIDIUniqueID = 998871

    doAndWaitFor(expectation: .didUpdateConnections) {}

    let outputPort = doAndWaitFor(expectation: .didConnectTo(uniqueId: outputUniqueId), duration: 10.0) {
      self.midi.createOutputPort(uniqueId: outputUniqueId)
    }

    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(outputUniqueId) }
    XCTAssertTrue(midi.activeConnections.contains(outputUniqueId))

    let packetBuilder = MIDIEventList.Builder(inProtocol: ._2_0,
                                              wordSize: MemoryLayout<MIDIEventList>.size / MemoryLayout<UInt32>.stride)
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_91_60_7F)])
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_81_60_00)])

    _ = packetBuilder.withUnsafePointer {
      MIDIReceivedEventList(outputPort!, $0)
    }

    checkUntil(elapsed: 10.0) { !midi.channels.isEmpty }

    XCTAssertNotEqual(midi.channels, [:])
    XCTAssertNotEqual(midi.groups, [:])

    doAndWaitFor(expectation: .didStop) {
      self.midi.stop()
    }

    XCTAssertTrue(midi.activeConnections.isEmpty)
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
  }

  func testDisconnectWhenSourceGoesAway() {
    doAndWaitFor(expectation: .didUpdateConnections) {}

    self.createSource1()
    self.createSource2()

    let outputUniqueId: MIDIUniqueID = 998877
    let outputPort = doAndWaitFor(expectation: .didConnectTo(uniqueId: outputUniqueId)) {
      self.midi.createOutputPort(uniqueId: outputUniqueId)
    }

    checkUntil(elapsed: 2.0) {
      midi.activeConnections.contains(12346) &&
      midi.activeConnections.contains(12347) &&
      midi.activeConnections.contains(outputUniqueId)
    }

    XCTAssertFalse(midi.activeConnections.isEmpty)
    let numRefCons = midi.refCons.count
    XCTAssertTrue(numRefCons >= 3)

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

    MIDIEndpointDispose(source2)
    MIDIEndpointDispose(source1)

    checkUntil(elapsed: 2.0) { !midi.activeConnections.contains(12347) && !midi.activeConnections.contains(12346) }

    doAndWaitFor(expectation: .didStop, duration: 10.0) { self.midi.stop() }

    XCTAssertTrue(midi.activeConnections.isEmpty)
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
    XCTAssertTrue(numRefCons > midi.refCons.count)
  }
}

#endif
