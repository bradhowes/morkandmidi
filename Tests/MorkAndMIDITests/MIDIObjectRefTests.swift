// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MIDIObjectRefTests: XCTestCase {

  let clientName = "TestClient"
  var client: MIDIClientRef = .init()

  override func setUp() async throws {
    client = .init()
    let err = MIDIClientCreateWithBlock(clientName as CFString, &client, nil)
    XCTAssertEqual(err, noErr)
  }

  override func tearDown() {
    MIDIClientDispose(client)
    client = .init()
  }

  func testUnknownProp() {
    XCTAssertEqual(client.get("blahblahblah" as CFString), "")
    let endpoint = MIDIEndpointRef()
    XCTAssertEqual(endpoint.name, "")
    XCTAssertEqual(endpoint.displayName, "")
    XCTAssertEqual(endpoint.manufacturer, "")
  }
  
  func testName() {
    XCTAssertEqual(client.name, clientName)
    client.name = "TestClient2"
    XCTAssertEqual(client.name, "TestClient2")
  }

  func testModel() {
    XCTAssertEqual(client.model, "")
    client.model = "Model T"
    XCTAssertEqual(client.model, "Model T")
  }

  func testManufacturer() {
    XCTAssertEqual(client.manufacturer, "")
    client.manufacturer = "ApplePie"
    XCTAssertEqual(client.manufacturer, "ApplePie")
  }

  func testDisplayName() {
    let sourceName = "Source1"
    var source = MIDIEndpointRef()
    let err = MIDISourceCreateWithProtocol(client, sourceName as CFString, ._2_0, &source)
    XCTAssertEqual(err, noErr)
    XCTAssertEqual(source.displayName, "Source1")
  }

  func testUniqueId() {
    let source1Name = "Source1"
    var source1 = MIDIEndpointRef()
    var err = MIDISourceCreateWithProtocol(client, source1Name as CFString, ._2_0, &source1)
    XCTAssertEqual(err, noErr)
    source1.uniqueId = 1
    XCTAssertEqual(source1.uniqueId, 1)

    let source2Name = "Source2"
    var source2 = MIDIEndpointRef()
    err = MIDISourceCreateWithProtocol(client, source2Name as CFString, ._2_0, &source2)
    XCTAssertEqual(err, noErr)
    source2.uniqueId = 1
    XCTAssertNotEqual(source2.uniqueId, 1)
    source2.uniqueId = 2
    XCTAssertEqual(source2.uniqueId, 2)
  }

  func testVisibility() {
    var client = MIDIClientRef()
    let clientName = "TestClient"
    let err = MIDIClientCreateWithBlock(clientName as CFString, &client, nil)
    XCTAssertEqual(err, noErr)
    XCTAssertEqual(client.hidden, false)
    client.hidden = true
    XCTAssertEqual(client.hidden, true)
    client.hidden = false
    XCTAssertEqual(client.hidden, false)
  }
}
