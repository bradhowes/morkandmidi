// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class SourcesTests: XCTestCase {

  var midi: MIDI!
  var monitor: Monitor!

  override func setUp() {
    super.setUp()
    midi = MIDI(clientName: "foo", uniqueId: 12_345)
    monitor = Monitor(self)
    midi.monitor = monitor
    monitor.setExpectation(.initialized)
    midi.start()
    waitForExpectations(timeout: 15.0)
  }

  override func tearDown() {
    midi.stop()
    midi = nil
    super.tearDown()
  }

  func testIndexing() {
    let sources = Sources()
    XCTAssertTrue(sources.count > 0)
    let endpoint = sources[0]
    XCTAssertNotNil(endpoint)
  }

  func testIteration() {
    var seen = 0
    for _ in Sources() {
      seen += 1
    }

    XCTAssertTrue(seen > 0)
  }

  func testUniqueIds() {
    let uniqueIds = Sources().uniqueIds
    XCTAssertTrue(uniqueIds.count > 0)
  }

  func testDisplayNames() {
    let displayNames = Sources().displayNames
    XCTAssertTrue(displayNames.count > 0)
    XCTAssertTrue(displayNames[0].count > 0)
  }
}
