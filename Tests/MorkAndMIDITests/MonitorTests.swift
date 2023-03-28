// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MonitorTests: MonitoredTestCase {

  override func setUp() {
    super.setUp()
    initialize(clientName: "Na-nu Na-nu", uniqueId: 123_456)
  }

  override func tearDown() {
    midi = nil
    monitor = nil
    super.tearDown()
  }

  func testDidInitialize() {
    doAndWaitFor(expectation: .didInitialize)
  }

  func testWillUninitialize() {
    doAndWaitFor(expectation: .willUninitialize, start: false) {
      self.midi = nil
    }
  }

  func testDidCreateInputPort() {
    doAndWaitFor(expectation: .didCreateInputPort)
  }

  func testWIllDeleteInputPort() {
    doAndWaitFor(expectation: .didCreateInputPort) {}
    doAndWaitFor(expectation: .willDeleteInputPort) {
      self.midi.stop()
    }
  }

  func testWillUpdateConnections() {
    doAndWaitFor(expectation: .willUpdateConnections(lookingFor: [uniqueId + 1, uniqueId + 2])) {
      self.createSource1()
      self.createSource2()
    }
  }

  func testShouldConnectTo() {
    monitor.shouldConnectTo = [uniqueId + 2]

    doAndWaitFor(expectation: .didConnectTo(uniqueId: uniqueId + 2)) {
      self.createSource1()
      self.createSource2()
    }

    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(uniqueId + 2) }
    XCTAssertFalse(midi.activeConnections.contains(uniqueId + 1))
  }

  func testDidConnectTo() {
    doAndWaitFor(expectation: .didConnectTo(uniqueId: uniqueId + 2)) {
      self.createSource1()
      self.createSource2()
    }
  }

  func testDidUpdateConnections() {
    doAndWaitFor(expectation: .didUpdateConnections) {
      self.createSource1()
    }
  }

  func testSending() {
    let ourUniqueId: MIDIUniqueID = 11223344
    monitor.shouldConnectTo = [ourUniqueId]

    let outputPort = doAndWaitFor(expectation: .didConnectTo(uniqueId: ourUniqueId)) {
      self.midi.createOutputPort(uniqueId: ourUniqueId)
    }

    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(ourUniqueId) }
    XCTAssertTrue(midi.activeConnections.contains(ourUniqueId))

    let packetBuilder = MIDIEventList.Builder(inProtocol: ._2_0,
                                              wordSize: MemoryLayout<MIDIEventList>.size / MemoryLayout<UInt32>.stride)
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_91_60_7F)])
    packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_81_60_00)])

    doAndWaitFor(expectation: .didSee(uniqueId: ourUniqueId), duration: 10.0) {
      self.monitor.expectation.expectedFulfillmentCount = packetBuilder.count
      _ = packetBuilder.withUnsafePointer {
        MIDIReceivedEventList(outputPort!, $0)
      }
    }
  }

  class DummyMonitor: MorkAndMIDI.Monitor {}

  func testMonitorProtocolDefaultStubs() {
    let dummy = DummyMonitor()
    dummy.didConnect(to: .init())
    dummy.didCreate(inputPort: .init())
    dummy.didInitialize(uniqueId: 1_234)
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
