// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MIDINotificationMessageIDTests: XCTestCase {

  func testNames() {
    XCTAssertEqual(MIDINotificationMessageID.msgSetupChanged.tag, "msgSetupChanged")
    XCTAssertEqual(MIDINotificationMessageID.msgObjectAdded.tag, "msgObjectAdded")
    XCTAssertEqual(MIDINotificationMessageID.msgObjectRemoved.tag, "msgObjectRemoved")
    XCTAssertEqual(MIDINotificationMessageID.msgPropertyChanged.tag, "msgPropertyChanged")
    XCTAssertEqual(MIDINotificationMessageID.msgIOError.tag, "msgIOError")
    XCTAssertEqual(MIDINotificationMessageID.msgThruConnectionsChanged.tag, "msgThruConnectionsChanged")
    XCTAssertEqual(MIDINotificationMessageID.msgSerialPortOwnerChanged.tag, "msgSerialPortOwnerChanged")
  }
}
