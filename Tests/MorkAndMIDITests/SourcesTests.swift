// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class SourcesTests: XCTestCase {

  var midi: MIDI!
  var monitor: Monitor!
  var sources: Sources!

  override func setUp() {
    super.setUp()
    midi = MIDI(clientName: "foo", uniqueId: 12_345)
    monitor = Monitor(self)
    midi.monitor = monitor
    monitor.setExpectation(.initialized)
    midi.start()
    waitForExpectations(timeout: 15.0)
    sources = Sources()
  }

  override func tearDown() {
    midi.stop()
    midi = nil
    super.tearDown()
  }

  func testIndexing() {
    guard !sources.isEmpty else { return }
    let endpoint = sources[0]
    XCTAssertNotNil(endpoint)
  }

  func testIteration() {
    guard !sources.isEmpty else { return }
    var seen = 0
    for _ in sources {
      seen += 1
    }

    XCTAssertTrue(seen > 0)
  }

  func testUniqueIds() {
    guard !sources.isEmpty else { return }
    let uniqueIds = sources.uniqueIds
    XCTAssertTrue(uniqueIds.count > 0)
  }

  func testDisplayNames() {
    guard !sources.isEmpty else { return }
    let displayNames = sources.displayNames
    XCTAssertTrue(displayNames.count > 0)
    XCTAssertTrue(displayNames[0].count > 0)
  }
}
