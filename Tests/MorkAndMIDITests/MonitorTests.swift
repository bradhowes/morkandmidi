// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MonitorTests: MIDITestCase {

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testDidInitialize() {
    midi.stop()
    doAndWaitFor(expected: .didInitialize) {
      midi.start()
    }
  }

  func testWillUninitialize() {
    doAndWaitFor(expected: .willUninitialize) {
      midi = nil
    }
  }

  func testDidCreateInputPort() {
    createMIDIWithoutStarting()
    doAndWaitFor(expected: .didCreateInputPort) {
      midi.start()
    }
  }

  func testWIllDeleteInputPort() {
    doAndWaitFor(expected: .willDeleteInputPort) {
      midi.stop()
    }
  }

  func testWillUpdateConnections() {
    createSource1()
    checkUntil(elapsed: 10) { midi.activeConnections.contains(source1.uniqueId) }
    doAndWaitFor(expected: .willUpdateConnections) {
      MIDIEndpointDispose(source1)
      source1 = .init()
    }
    checkUntil(elapsed: 10) { !midi.activeConnections.contains(source1.uniqueId) }
  }

  func testShouldConnectTo() {
    self.createSource1()
    self.createSource2()

    midi.stop()
    createMIDIWithoutStarting()

    let monitor = TestMonitor()
    midi.monitor = monitor
    monitor.shouldConnectTo = [uniqueId + 1]

    midi.start()

    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(uniqueId + 1) }
    XCTAssertFalse(midi.activeConnections.contains(uniqueId + 2))
  }

  func testDidUpdateConnections() {
    createSource1()
    doAndWaitFor(expected: .didUpdateConnections) {
      MIDIEndpointDispose(source1)
      source1 = .init()
    }
  }

  func testSending() {
    createSource1()
    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(source1.uniqueId) }

    let packetBuilder = MIDIEventList.Builder(inProtocol: ._2_0,
                                              wordSize: MemoryLayout<MIDIEventList>.size / MemoryLayout<UInt32>.stride)
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_91_60_7F)])
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_81_60_00)])

    XCTAssertTrue(midi.channels.isEmpty)
    _ = packetBuilder.withUnsafePointer {
      MIDIReceivedEventList(source1, $0)
    }

    checkUntil(elapsed: 5.0) { midi.channels[source1.uniqueId] != nil }
  }

  class DummyMonitor: MorkAndMIDI.MonitorWithDefaults {}

  func testMonitorProtocolDefaultStubs() {
    let dummy = DummyMonitor()
    dummy.didConnect(to: .init())
    dummy.didCreate(inputPort: .init())
    dummy.didInitialize()
    dummy.didSee(uniqueId: 1_234, group: 2, channel: 3)
    dummy.willDelete(inputPort: .init())
    dummy.willUninitialize()
    dummy.willUpdateConnections()
    dummy.didStart()
    dummy.didStop()
    dummy.didUpdateConnections(connected: [], disappeared: [])
    _ = dummy.shouldConnect(to: .init())
  }
}
