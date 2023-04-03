// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

#if os(macOS)
class MIDITests: MIDITestCase {

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testPreStartInitialState() {
    createMIDIWithoutStarting()
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
    XCTAssertTrue(midi.activeConnections.isEmpty)
    XCTAssertFalse(midi.isRunning)
    XCTAssertEqual(midi.model, "")
    XCTAssertEqual(midi.manufacturer, "")
    XCTAssertTrue(midi.enableNetworkConnections)
  }

  func testPostStartInitialState() {
    midi.stop()
    XCTAssertFalse(midi.isRunning)
    doAndWaitFor(expected: .didCreateInputPort) {
      midi.start()
    }
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
    XCTAssertTrue(midi.isRunning)
  }

  func testStartStopStartSucceeds() {
    //
    _ = midi.createClient()
    _ = midi.createInputPort()
    doAndWaitFor(expected: .didStop) { self.midi.stop() }
    doAndWaitFor(expected: .didStart) { self.midi.start() }
  }

  func testCreatingClientOnce() {
    _ = midi.createClient()
    XCTAssertTrue(midi.isRunning)
  }

  func testCreatingInputPortOnce() {
    _ = midi.createInputPort()
    XCTAssertTrue(midi.isRunning)
  }

  func testManufactureProperty() {
    midi.manufacturer = "B-Ray Software"
    XCTAssertEqual(midi.manufacturer, "B-Ray Software")
    XCTAssertEqual(midi.inputPort.manufacturer, midi.manufacturer)
  }

  func testModelProperty() {
    midi.model = "SoundFonts"
    XCTAssertEqual(midi.model, "SoundFonts")
    XCTAssertEqual(midi.inputPort.model, midi.model)
  }

  func testEnableNetworkConnections() {
    let mns = MIDINetworkSession.default()
    // As a package, this test has no effect on MIDINetworkSession.
    midi.enableNetworkConnections = true
    XCTAssertEqual(mns.connectionPolicy, .noOne)
    midi.enableNetworkConnections = false
    XCTAssertEqual(mns.connectionPolicy, .noOne)

  }

  func testStopResetsState() {
    let outputUniqueId: MIDIUniqueID = 998871

    let outputPort = self.midi.createOutputPort(uniqueId: outputUniqueId)
    checkUntil(elapsed: 10.0) { midi.activeConnections.contains(outputUniqueId) }

    XCTAssertTrue(midi.activeConnections.contains(outputUniqueId))

    let packetBuilder = MIDIEventList.Builder(inProtocol: ._2_0,
                                              wordSize: MemoryLayout<MIDIEventList>.size / MemoryLayout<UInt32>.stride)
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_91_60_7F)])
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_81_60_00)])

    _ = packetBuilder.withUnsafePointer {
      MIDIReceivedEventList(outputPort, $0)
    }

    checkUntil(elapsed: 10.0) { !midi.channels.isEmpty }

    XCTAssertNotEqual(midi.channels, [:])
    XCTAssertNotEqual(midi.groups, [:])

    doAndWaitFor(expected: .didStop) {
      self.midi.stop()
    }

    XCTAssertTrue(midi.activeConnections.isEmpty)
    XCTAssertTrue(midi.channels.isEmpty)
    XCTAssertTrue(midi.groups.isEmpty)
  }

  func testDisconnectWhenSourceGoesAway() {
    createSource1()
    createSource2()

    checkUntil(elapsed: 10.0) { midi.activeConnections.contains(source1.uniqueId) }
    checkUntil(elapsed: 10.0) { midi.activeConnections.contains(source2.uniqueId) }

    MIDIEndpointDispose(source1)
    checkUntil(elapsed: 10.0) { !midi.activeConnections.contains(source1.uniqueId) }
    midi.disconnect(from: source1.uniqueId)

    midi.disconnect(from: source2.uniqueId)
    MIDIEndpointDispose(source2)
    checkUntil(elapsed: 10.0) { !midi.activeConnections.contains(source2.uniqueId) }

  }

  func testConnectToDisconnectFrom() {
    createSource2()
    let uniqueId = source2.uniqueId
    checkUntil(elapsed: 10.0) { midi.activeConnections.contains(uniqueId) }
    midi.disconnect(from: uniqueId)
    checkUntil(elapsed: 10.0) { !midi.activeConnections.contains(uniqueId) }
    XCTAssertTrue(midi.connect(to: uniqueId))
    checkUntil(elapsed: 10.0) { midi.activeConnections.contains(uniqueId) }
  }
}

#endif
