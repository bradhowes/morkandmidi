// Copyright © 2021-2026 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class OSStatusTests: XCTestCase {

  func testNames() {
    XCTAssertEqual(noErr.tag, "OK")
    XCTAssertEqual(kMIDIInvalidClient.tag, "kMIDIInvalidClient")
    XCTAssertEqual(kMIDIInvalidPort.tag, "kMIDIInvalidPort")
    XCTAssertEqual(kMIDIWrongEndpointType.tag, "kMIDIWrongEndpointType")
    XCTAssertEqual(kMIDINoConnection.tag, "kMIDINoConnection")
    XCTAssertEqual(kMIDIUnknownEndpoint.tag, "kMIDIUnknownEndpoint")
    XCTAssertEqual(kMIDIUnknownProperty.tag, "kMIDIUnknownProperty")
    XCTAssertEqual(kMIDIWrongPropertyType.tag, "kMIDIWrongPropertyType")
    XCTAssertEqual(kMIDINoCurrentSetup.tag, "kMIDINoCurrentSetup")
    XCTAssertEqual(kMIDIMessageSendErr.tag, "kMIDIMessageSendErr")
    XCTAssertEqual(kMIDIServerStartErr.tag, "kMIDIServerStartErr")
    XCTAssertEqual(kMIDISetupFormatErr.tag, "kMIDISetupFormatErr")
    XCTAssertEqual(kMIDIWrongThread.tag, "kMIDIWrongThread")
    XCTAssertEqual(kMIDIObjectNotFound.tag, "kMIDIObjectNotFound")
    XCTAssertEqual(kMIDIIDNotUnique.tag, "kMIDIIDNotUnique")
    XCTAssertEqual(kMIDINotPermitted.tag, "kMIDINotPermitted")
    XCTAssertEqual(kMIDIMessageSendErr.tag, "kMIDIMessageSendErr")
    XCTAssertEqual(kMIDIUnknownError.tag, "???")
  }

  func testWasSuccessful() {
    XCTAssertTrue(noErr.wasSuccessful(log, "hello"))
    XCTAssertFalse(kMIDIInvalidPort.wasSuccessful(log, "hello"))
  }
}

private let log: Logger = .init(category: "OSStatusTests")
