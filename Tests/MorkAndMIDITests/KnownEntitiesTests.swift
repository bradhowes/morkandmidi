// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

// Note on tests: these tests run great on my laptop, but on a CI box at Github, they would sometimes fail, presumably
// because of latency between the iOS MIDI server that has a view of the MIDI universe and the client (the test). So,
// when there is nothing captured in `sources` these tests just silently exit without doing any actual testing.s
//
// A better way would be to mock out the CoreMIDI API so as to guarantee an environment in which to test the code...

class KnownSourcesTests: XCTestCase {

  let uniqueId: MIDIUniqueID = 12_345

  var midi: MIDI!
  var monitor: Monitor!
  var client: MIDIClientRef = .init()
  var source1: MIDIEndpointRef = .init()
  var source2: MIDIEndpointRef = .init()

  override func setUp() {
    super.setUp()
    midi = MIDI(clientName: "foo", uniqueId: uniqueId)
    midi.start()

    let monitor = Monitor(self)
    midi.monitor = monitor
    monitor.pushExpectation(.willUpdateConnections(lookingFor: [uniqueId + 1, uniqueId + 2]))

    var err = MIDIClientCreateWithBlock("TestSource" as CFString, &client, nil)
    XCTAssertEqual(err, noErr)

    err = MIDISourceCreateWithProtocol(client, "Source1" as CFString, ._2_0, &source1)
    XCTAssertEqual(err, noErr)
    source1.uniqueId = uniqueId + 1

    err = MIDISourceCreateWithProtocol(client, "Source2" as CFString, ._2_0, &source2)
    XCTAssertEqual(err, noErr)
    source2.uniqueId = uniqueId + 2

    monitor.waitForExpectation()
  }

  override func tearDown() {
    MIDIClientDispose(client)
    midi = nil
    super.tearDown()
  }

  func testIndexing() {
    let endpoint = KnownSources()[0]
    XCTAssertNotNil(endpoint)
  }

  func testIteration() {
    var seen = 0
    for _ in KnownSources() {
      seen += 1
    }

    XCTAssertTrue(seen > 0)
  }

  func testUniqueIds() {
    let uniqueIds = KnownSources.all.uniqueIds
    XCTAssertTrue(uniqueIds.count > 0)
  }

  func testDisplayNames() {
    let displayNames = KnownSources.all.displayNames
    XCTAssertNotNil(displayNames)
  }

  func testMatchByName() {
    let sources = KnownSources.all
    let first = sources[0]
    print(first.uniqueId, first.name)
    let found = KnownSources.matching(name: sources[sources.count - 1].name)
    print(found[0].uniqueId, found[0].name)
    XCTAssertFalse(found.isEmpty)
    XCTAssertNotEqual(first, found[0])
  }

  func testMatchByUniqueId() {
    let sources = KnownSources.all
    let first = sources[0]
    print(first.uniqueId, first.name)
    XCTAssertNotNil(KnownSources.matching(uniqueId: uniqueId + 1))
    XCTAssertNotNil(KnownSources.matching(uniqueId: uniqueId + 2))
    XCTAssertNil(KnownSources.matching(uniqueId: uniqueId + 3))
  }
}
