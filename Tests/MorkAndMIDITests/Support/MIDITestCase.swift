// Copyright © 2023-2026 Brad Howes. All rights reserved.
import os
@testable import MorkAndMIDI
import CoreMIDI
import XCTest


class MIDITestCase: XCTestCase {

  let uniqueId: MIDIUniqueID = 987_654
  var midi: MIDI!
  var client: MIDIClientRef = .init()
  var source1: MIDIEndpointRef = .init()
  var source2: MIDIEndpointRef = .init()
  var receiver: TestReceiver!
  var monitor: TestMonitor!

  typealias BlockNoReturn = () -> Void
  typealias BlockWithMonitorNoReturn = (TestMonitor) -> Void

  override func setUp() {
    super.setUp()
    client = .init()
    source1 = .init()
    source2 = .init()
    receiver = TestReceiver()
    monitor = TestMonitor()
    createMIDIWithoutStarting()
    doAndWaitFor(expected: .didUpdateConnections) { _, _ in
      self.midi.start()
    }
  }

  override func tearDown() {
    if client != .init() { MIDIClientDispose(client) }
    if midi != nil {
      midi.stop()
      midi.monitor = nil
      midi.receiver = nil
    }
    midi = nil
    monitor = nil
    receiver = nil
    client = .init()
    source1 = .init()
    source2 = .init()
  }

  func createMIDIWithoutStarting(clientName: String = "MIDITestCase'", midiProto: MIDIProto = .v2_0) {
    if midi != nil {
      midi.stop()
      midi = nil
    }
    midi = MIDI(clientName: clientName, uniqueId: uniqueId, midiProto: midiProto)
    midi.monitor = monitor
    midi.receiver = receiver
  }

  func createClient() {
    guard client == .init() else { return }
    XCTAssertEqual(MIDIClientCreateWithBlock("TestSource" as CFString, &client, nil), noErr)
  }

  func createSource1(midiProtocol: MIDIProtocolID = ._2_0) {
    guard source1 == .init() else { return }
    createClient()
    doAndWaitFor(expected: .didUpdateConnections) { _, _ in
      XCTAssertEqual(MIDISourceCreateWithProtocol(self.client, "Source1" as CFString, midiProtocol,
                                                  &self.source1), noErr)
      source1.uniqueId = self.uniqueId + 1
    }
  }

  func createSource2(midiProtocol: MIDIProtocolID = ._2_0) {
    guard source2 == .init() else { return }
    createClient()
    doAndWaitFor(expected: .didUpdateConnections) { _, _ in
      XCTAssertEqual(MIDISourceCreateWithProtocol(self.client, "Source2" as CFString, midiProtocol,
                                                  &self.source2), noErr)
      source2.uniqueId = self.uniqueId + 2
    }
  }

  @discardableResult
  func doAndWaitFor<T>(expected: TestMonitor.ExpectationKind, duration: Double = 10.0, block: () -> T) -> T {
    let expectation = expectation(description: expected.description)
    let monitor = TestMonitor(expected: expected) { expectation.fulfill() }
    midi.monitor = monitor
    let value = block()
    wait(for: [expectation], timeout: duration)
    return value
  }

  @discardableResult
  func doAndWaitFor<T>(expected: TestMonitor.ExpectationKind, duration: Double = 10.0,
                       block: (TestMonitor, XCTestExpectation) -> T) -> T {
    let expectation = expectation(description: expected.description)
    let monitor = TestMonitor(expected: expected) { expectation.fulfill() }
    midi.monitor = monitor
    let value = block(monitor, expectation)
    wait(for: [expectation], timeout: duration)
    return value
  }
}
