// Copyright © 2021 Brad Howes. All rights reserved.
import os
@testable import MorkAndMIDI
import CoreMIDI
import XCTest

internal class Receiver: MorkAndMIDI.Receiver {

  enum ExpectationKind: String {
    case noteOff
    case noteOn
  }

  weak var test: XCTestCase?
  var channel: Int = -1
  var group: Int = -1
  var received = [String]()
  var expectationKind: ExpectationKind!
  var expectation: XCTestExpectation!

  init(_ test: XCTestCase) {
    self.test = test
  }

  func setExpectation(_ kind: ExpectationKind) {
    self.expectationKind = kind
    self.expectation = test?.expectation(description: kind.rawValue)
  }

  func fulfill(_ kind: ExpectationKind) {
    guard expectation != nil else { return }
    print("fulfill: ", kind.rawValue, expectationKind.rawValue)
    if kind == expectationKind {
      expectation.fulfill()
    }
  }

  func noteOff(note: UInt8, velocity: UInt8) {
    received.append("noteOff \(note) \(velocity)")
    fulfill(.noteOff)
  }
  func noteOff2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    received.append("noteOff2 \(note) \(velocity) \(attributeType) \(attributeData)")
    fulfill(.noteOff)
  }
  func noteOn(note: UInt8, velocity: UInt8) {
    received.append("noteOn \(note) \(velocity)")
    fulfill(.noteOn)
  }
  func noteOn2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    received.append("noteOn2 \(note) \(velocity) \(attributeType) \(attributeData)")
    fulfill(.noteOn)
  }
  func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {
    received.append("polyphonicKeyPressure \(note) \(pressure)")
  }
  func polyphonicKeyPressure2(note: UInt8, pressure: UInt32) {
    received.append("polyphonicKeyPressure2 \(note) \(pressure)")
  }
  func controlChange(controller: UInt8, value: UInt8) {
    received.append("controlChange \(controller) \(value)")
  }
  func controlChange2(controller: UInt8, value: UInt32) {
    received.append("controlChange2 \(controller) \(value)")
  }
  func programChange(program: UInt8) {
    received.append("programChange \(program)")
  }
  func programChange2(program: UInt8, bank: UInt16) {
    received.append("programChange2 \(program) \(bank)")
  }
  func channelPressure(pressure: UInt8) {
    received.append("channelPressure \(pressure)")
  }
  func channelPressure2(pressure: UInt32) {
    received.append("channelPressure2 \(pressure)")
  }
  func pitchBendChange(value: UInt16) {
    received.append("pitchBendChange \(value)")
  }
  func pitchBendChange2(value: UInt32) {
    received.append("pitchBendChange2 \(value)")
  }
  func timeCodeQuarterFrame(value: UInt8) {
    received.append("timeCodeQuarterFrame \(value)")
  }
  func songPositionPointer(value: UInt16) {
    received.append("songPositionPointer \(value)")
  }
  func songSelect(value: UInt8) {
    received.append("songSelect \(value)")
  }
  func tuneRequest() {
    received.append("tuneRequest")
  }
  func timingClock() {
    received.append("timingClock")
  }
  func startCurrentSequence() {
    received.append("startCurrentSequence")
  }
  func continueCurrentSequence() {
    received.append("continueCurrentSequence")
  }
  func stopCurrentSequence() {
    received.append("stopCurrentSequence")
  }
  func activeSensing() {
    received.append("activeSensing")
  }
  func reset() {
    received.append("reset")
  }
  func registeredPerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32) {
    received.append("registeredPerNoteControllerChange \(note) \(controller) \(value)")
  }
  func assignablePerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32) {
    received.append("assignablePerNoteControllerChange \(note) \(controller) \(value)")
  }
  func registeredControllerChange(controller: UInt16, value: UInt32) {
    received.append("registeredControllerChange \(controller) \(value)")
  }
  func assignableControllerChange(controller: UInt16, value: UInt32) {
    received.append("assignableControllerChange \(controller) \(value)")
  }
  func relativeRegisteredControllerChange(controller: UInt16, value: Int32) {
    received.append("relativeRegisteredControllerChange \(controller) \(value)")
  }
  func relativeAssignableControllerChange(controller: UInt16, value: Int32) {
    received.append("relativeAssignableControllerChange \(controller) \(value)")
  }
  func perNoteManagement(note: UInt8, detach: Bool, reset: Bool) {
    received.append("perNoteManagement \(note) \(detach) \(reset)")
  }
}

internal class Monitor: MorkAndMIDI.Monitor {
  private let log: OSLog = .init(subsystem: "Testing", category: "Monitor")

  enum ExpectationKind: CustomStringConvertible, Equatable, Hashable {
    var description: String {
      switch self {
      case .didInitialize: return "didInitialize"
      case .willUninitialize: return "willUnitialize"
      case .didCreateInputPort: return "didCreateInputPort"
      case .willDeleteInputPort: return "willDeleteInputPort"
      case .didStart: return "didStart"
      case .didStop: return "didStop"
      case .shouldConnectTo: return "shouldConnectTo"
      case .didConnectTo: return "didConnectTo"
      case .willUpdateConnections: return "willUpdateConnections"
      case .didUpdateConnections: return "didUpdateConnections"
      case .didSee: return "didSee"
      }
    }

    case didInitialize
    case willUninitialize
    case didCreateInputPort
    case willDeleteInputPort
    case didStart
    case didStop
    case shouldConnectTo
    case didConnectTo(uniqueId: MIDIUniqueID)
    case willUpdateConnections(lookingFor: [MIDIUniqueID])
    case didUpdateConnections
    case didSee(uniqueId: MIDIUniqueID)
  }

  weak var test: XCTestCase!
  var connectionChannels = [MIDIUniqueID: (group: Int, channel: Int)]()
  var shouldConnectTo = [MIDIUniqueID]()
  var ourUniqueId: MIDIUniqueID?

  struct ExpectationInfo {
    let kind: ExpectationKind
    let expectation: XCTestExpectation
    var fulfilled: Bool = false
  }

  var expectationStack = [ExpectationInfo]()

  init(_ test: XCTestCase) {
    self.test = test
  }
}

internal extension Monitor {

  var expectation: XCTestExpectation { expectationStack.last!.expectation }

  func pushExpectation(_ kind: ExpectationKind) {
    os_log(.info, log: log, "pushExpectation %{public}s", kind.description)
    expectationStack.append(.init(kind: kind, expectation: test!.expectation(description: kind.description)))
  }

  func fulfill(_ kind: ExpectationKind) {
    guard var expectationInfo = expectationStack.last else { return }
    os_log(.info, log: log, "fulfill %{public}s - next: %{public}s", kind.description, expectationInfo.kind.description)
    if kind == expectationInfo.kind && !expectationInfo.fulfilled {
      expectationInfo.expectation.fulfill()
      expectationInfo.fulfilled = true
      expectationStack[expectationStack.count - 1] = expectationInfo
    }
  }

  func waitForExpectation(sec timeout: Double = 5.0) {
    os_log(.info, log: log, "waitFoExpectation")
    guard let expectationInfo = expectationStack.last else { fatalError("no expectation to wait for") }
    os_log(.info, log: log, "expectation: %{public}s", expectationInfo.kind.description)
    self.test!.wait(for: [expectationInfo.expectation], timeout: timeout)
    _ = expectationStack.popLast()
  }

  func didInitialize(uniqueId: MIDIUniqueID) {
    ourUniqueId = uniqueId
    fulfill(.didInitialize)
  }

  func willUninitialize() { fulfill(.willUninitialize) }

  func didCreate(inputPort: MIDIPortRef) { fulfill(.didCreateInputPort) }

  func willDelete(inputPort: MIDIPortRef) { fulfill(.willDeleteInputPort) }

  func didStarf() { fulfill(.didStart) }

  func didStop() { fulfill(.didStop) }

  func willUpdateConnections() {
    guard let expectationInfo = expectationStack.last else { return }
    if case let .willUpdateConnections(lookingFor: uniqueIds) = expectationInfo.kind {
      let known = Set<MIDIUniqueID>(KnownSources.all.uniqueIds)
      let remainingUniqueIds = uniqueIds.filter { !known.contains($0) }
      if remainingUniqueIds.isEmpty {
        expectationInfo.expectation.fulfill()
      } else {
        expectationStack[expectationStack.count - 1] =
          .init(kind: .willUpdateConnections(lookingFor: remainingUniqueIds), expectation: expectationInfo.expectation)
      }
    }
  }

  func shouldConnect(to endpoint: MIDIEndpointRef) -> Bool {
    fulfill(.shouldConnectTo)
    return shouldConnectTo.isEmpty || shouldConnectTo.contains(endpoint.uniqueId)
  }

  func didConnect(to endpoint: MIDIEndpointRef) {
    guard let expectationInfo = expectationStack.last else { return }
    if case let .didConnectTo(uniqueId: expectedUniqueId) = expectationInfo.kind {
      if endpoint.uniqueId == expectedUniqueId {
        expectationInfo.expectation.fulfill()
      }
    }
  }

  func didUpdateConnections(connected: any Sequence<MIDIEndpointRef>, disappeared: any Sequence<MIDIUniqueID>) {
    fulfill(.didUpdateConnections)
  }

  func didSee(uniqueId: MIDIUniqueID, group: Int, channel: Int) {
    connectionChannels[uniqueId] = (group: group, channel: channel)
    guard let expectationInfo = expectationStack.last else { return }
    if case let .didSee(uniqueId: expectedUniqueId) = expectationInfo.kind {
      if uniqueId == expectedUniqueId {
        expectationInfo.expectation.fulfill()
      }
    }
  }
}

extension XCTestCase {

  public func delay(sec timeout: Double) {
    let delayExpectation = XCTestExpectation()
    delayExpectation.isInverted = true
    wait(for: [delayExpectation], timeout: timeout)
  }

  struct Timer {
    let start = Date()
    var elapsed: TimeInterval { start.distance(to: Date()) }
  }

  public func checkUntil(elapsed: TimeInterval, pause: Double = 0.1, _ condition: () -> Bool) {
    let timer = Timer()
    while !condition() && timer.elapsed < elapsed {
      delay(sec: pause)
    }
  }
}

class MonitoredTestCase : XCTestCase {

  var midi: MIDI!
  var monitor: Monitor!
  var uniqueId: MIDIUniqueID!
  var client: MIDIClientRef = .init()
  var source1: MIDIEndpointRef = .init()
  var source2: MIDIEndpointRef = .init()

  func initialize(clientName: String, uniqueId: MIDIUniqueID) {
    self.uniqueId = uniqueId
    self.midi = MIDI(clientName: clientName, uniqueId: uniqueId)
    monitor = Monitor(self)
    midi.monitor = monitor
  }

  func createSource1() {
    monitor.pushExpectation(.willUpdateConnections(lookingFor: [uniqueId + 1]))

    var err = MIDIClientCreateWithBlock("TestSource" as CFString, &client, nil)
    XCTAssertEqual(err, noErr)

    err = MIDISourceCreateWithProtocol(client, "Source1" as CFString, midi.midiProtocol, &source1)
    XCTAssertEqual(err, noErr)
    source1.uniqueId = uniqueId + 1

    monitor.waitForExpectation()
  }

  func createSource2() {
    let err = MIDISourceCreateWithProtocol(client, "Source2" as CFString, midi.midiProtocol, &source2)
    XCTAssertEqual(err, noErr)
    source2.uniqueId = uniqueId + 2
  }

  func doAndWaitFor(expectation: Monitor.ExpectationKind, duration: Double = 5.0, start: Bool = true,
                    block: (() -> Void)? = nil) {
    monitor.pushExpectation(expectation)
    if start {
      // DispatchQueue.global(qos: .utility).async { self.midi.start() }
      midi.start()
      delay(sec: 0.2)
    }
    block?()
    monitor.waitForExpectation(sec: duration)
  }

  @discardableResult
  func doAndWaitFor<T>(expectation: Monitor.ExpectationKind, duration: Double = 5.0, start: Bool = true,
                       block: (() -> T)? = nil) -> T? {
    monitor.pushExpectation(expectation)
    if start { midi.start() }
    let value = block?()
    monitor.waitForExpectation(sec: duration)
    return value
  }
}
