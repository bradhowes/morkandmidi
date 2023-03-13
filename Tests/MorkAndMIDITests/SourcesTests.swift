// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

// Note on tests: these tests run great on my laptop, but on a CI box at Github, they would sometimes fail, presumably
// because of latency between the iOS MIDI server that has a view of the MIDI universe and the client (the test). So,
// when there is nothing captured in `sources` these tests just silently exit without doing any actual testing.s
//
// A better way would be to mock out the CoreMIDI API so as to guarantee an environment in which to test the code...

class SourcesTests: XCTestCase {

  var midi: MIDI!
  var monitor: Monitor!
  var sources: Sources!

  override func setUp() {
    super.setUp()
    midi = MIDI(clientName: "foo", uniqueId: 12_345)
    monitor = Monitor(self)
    midi.monitor = monitor
    monitor.setExpectation(.updatedDevices)
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
    let endpoint = sources[0]
    XCTAssertNotNil(endpoint)
  }

  func testIteration() {
    var seen = 0
    for _ in sources {
      seen += 1
    }

    XCTAssertTrue(seen > 0)
  }

  func testUniqueIds() {
    let uniqueIds = sources.uniqueIds
    XCTAssertTrue(uniqueIds.count > 0)
  }

  func testDisplayNames() {
    let displayNames = sources.displayNames
    XCTAssertNotNil(displayNames)
  }
}
