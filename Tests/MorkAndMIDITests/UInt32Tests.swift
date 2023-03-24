// Copyright © 2021 Brad Howes. All rights reserved.

import XCTest
@testable import MorkAndMIDI

class UInt32Tests: XCTestCase {

  func testUInt32Bytes() {
    let z = UInt32(0x12_34_56_78)
    XCTAssertEqual(z.b0, 0x12)
    XCTAssertEqual(z.b1, 0x34)
    XCTAssertEqual(z.b2, 0x56)
    XCTAssertEqual(z.b3, 0x78)
    let y = UInt32(0x41_A3_FF_FF)
    XCTAssertEqual(y.b0, 0x41)
    XCTAssertEqual(y.b1, 0xA3)
    XCTAssertEqual(y.b2, 0xFF)
    XCTAssertEqual(y.b3, 0xFF)
  }

  func testUInt32Shorts() {
    let z = UInt32(0x12_34_56_78)
    XCTAssertEqual(z.s0, 0x1234)
    XCTAssertEqual(z.s1, 0x5678)
  }
}
