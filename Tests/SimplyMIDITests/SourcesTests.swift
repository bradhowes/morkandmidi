// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SimplyMIDI
import CoreMIDI
import XCTest

class SourcesTests: XCTestCase {

  func testIndexing() {
    let sources = SimplyMIDI.Sources()
    XCTAssertTrue(sources.count > 0)
    let endpoint = sources[0]
    XCTAssertNotNil(endpoint)
  }

  func testIteration() {
    var seen = 0
    for _ in SimplyMIDI.Sources() {
      seen += 1
    }

    XCTAssertTrue(seen > 0)
  }

  func testUniqueIds() {
    let uniqueIds = SimplyMIDI.Sources().uniqueIds
    XCTAssertTrue(uniqueIds.count > 0)
  }

  func testDisplayNames() {
    let displayNames = SimplyMIDI.Sources().displayNames
    XCTAssertTrue(displayNames.count > 0)
    XCTAssertTrue(displayNames[0].count > 0)
  }
}
