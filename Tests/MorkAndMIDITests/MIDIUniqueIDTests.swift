// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import XCTest
@testable import MorkAndMIDI

class MIDIUniqueIDTests: XCTestCase {

  func testBoxingRoundtrip() {
    let uniqueId: MIDIUniqueID = 123
    let refCon = uniqueId.boxed
    let unboxed = MIDIUniqueID.unbox(refCon)
    XCTAssertEqual(unboxed, uniqueId)
  }

  func testUnboxingNilIsSafe() {
    XCTAssertNil(MIDIUniqueID.unbox(nil))
  }
}
