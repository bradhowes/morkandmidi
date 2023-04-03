// Copyright © 2021 Brad Howes. All rights reserved.
import os
@testable import MorkAndMIDI
import CoreMIDI
import XCTest

internal class TestMonitor: Monitor {

  private let log: OSLog = .init(subsystem: "Testing", category: "Monitor")

  typealias Fulfiller = () -> Void

  enum ExpectationKind: CustomStringConvertible, Equatable, Hashable {
    case didInitialize
    case willUninitialize
    case didCreateInputPort
    case willDeleteInputPort
    case didStart
    case didStop
    case shouldConnectTo
    case didConnectTo
    case willUpdateConnections
    case didUpdateConnections
    case didSee

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
  }

  var connectionChannels = [MIDIUniqueID: (group: Int, channel: Int)]()
  var shouldConnectTo = [MIDIUniqueID]()

  let expected: ExpectationKind?
  let fulfiller: Fulfiller?

  var didConnectToValues = [MIDIUniqueID]()
  var didSeeValues = [(uniqueId: MIDIUniqueID, group: Int, channel: Int)]()

  init() {
    self.expected = nil
    self.fulfiller = nil
  }

  init(expected: ExpectationKind, fulfiller: @escaping Fulfiller) {
    self.expected = expected
    self.fulfiller = fulfiller
  }

  func fulfill(_ kind: ExpectationKind) { if kind == expected { fulfiller?() } }
}

internal extension TestMonitor {

  func didInitialize() { fulfill(.didInitialize) }

  func willUninitialize() { fulfill(.willUninitialize) }
  func didCreate(inputPort: MIDIPortRef) { fulfill(.didCreateInputPort) }
  func willDelete(inputPort: MIDIPortRef) { fulfill(.willDeleteInputPort) }
  func didStart() { fulfill(.didStart) }
  func didStop() { fulfill(.didStop) }
  func willUpdateConnections() { fulfill(.willUpdateConnections) }

  func shouldConnect(to uniqueId: MIDIUniqueID) -> Bool {
    fulfill(.shouldConnectTo)
    return shouldConnectTo.isEmpty || shouldConnectTo.contains(uniqueId)
  }

  func didConnect(to uniqueId: MIDIUniqueID) {
    didConnectToValues.append(uniqueId)
    fulfill(.didConnectTo)
  }

  func didUpdateConnections(connected: any Sequence<MIDIEndpointRef>, disappeared: any Sequence<MIDIUniqueID>) {
    fulfill(.didUpdateConnections)
  }

  func didSee(uniqueId: MIDIUniqueID, group: Int, channel: Int) {
    didSeeValues.append((uniqueId: uniqueId, group: group, channel: channel))
    fulfill(.didSee)
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
    XCTAssertTrue(timer.elapsed < elapsed)
  }
}

