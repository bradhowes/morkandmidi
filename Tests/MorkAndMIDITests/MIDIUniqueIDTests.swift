// Copyright © 2021-2026 Brad Howes. All rights reserved.

import CoreMIDI
import XCTest

// not `@testable` to make sure the attributes being tested are public
import MorkAndMIDI

class MIDIUniqueIDTests: XCTestCase {

  func testBoxingRoundtrip() {
    let uniqueId: MIDIUniqueID = 123
    let refCon = uniqueId.boxed
    let unboxed = MIDIUniqueID.unbox(refCon)
    XCTAssertEqual(unboxed, uniqueId)
  }

  func testAsHex() {
    XCTAssertEqual(MIDIUniqueID(-1).asHex,  "0xFFFFFFFF")
    XCTAssertEqual(MIDIUniqueID(123).asHex, "0x0000007B")
  }
}
