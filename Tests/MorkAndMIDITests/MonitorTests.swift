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
    createSource1()
    createSource2()

    midi.stop()
    createMIDIWithoutStarting()

    let monitor = TestMonitor()
    midi.monitor = monitor
    monitor.shouldConnectTo = [uniqueId + 1]

    midi.start()

    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(uniqueId + 1) }
    XCTAssertFalse(midi.activeConnections.contains(uniqueId + 2))
  }

  func testSourceConnections() {
//    createSource1()
//    createSource2()
//
//    midi.stop()
//    createMIDIWithoutStarting()
//
//    doAndWaitFor(expected: .didConnectTo) {
//      midi.start()
//    }
//
//    for each in midi.sourceConnections {
//      print(each.uniqueId, each.displayName, each.connected, each.channel ?? -1, each.group ?? -1)
//    }
//
//    doAndWaitFor(expected: .didUpdateConnections) {
//      MIDIEndpointDispose(source1)
//      source1 = .init()
//      MIDIEndpointDispose(source2)
//      source2 = .init()
//    }
//
//    for each in midi.sourceConnections {
//      print(each.uniqueId, each.displayName, each.connected, each.channel ?? -1, each.group ?? -1)
//    }
  }

  func testDidUpdateConnections() {
    createSource1()
    doAndWaitFor(expected: .didUpdateConnections) {
      MIDIEndpointDispose(source1)
      source1 = .init()
    }
  }

  func testEmptyClientName() {
    midi = .init(clientName: "", uniqueId: 123, midiProto: .legacy)
    midi.start()
    createSource1()
    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(source1.uniqueId) }

    let packetBuilder = MIDIPacketList.Builder(byteSize: MemoryLayout<MIDIPacketList>.size / MemoryLayout<UInt8>.stride)
    packetBuilder.append(timestamp: mach_absolute_time(), data: [UInt8(0x81), UInt8(0x64), UInt8(0x65)])
    packetBuilder.append(timestamp: mach_absolute_time(), data: [UInt8(0x91), UInt8(0x64), UInt8(0x65)])

    XCTAssertTrue(midi.channels.isEmpty)
    _ = packetBuilder.withUnsafePointer {
      MIDIReceived(source1, $0)
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
