// Copyright © 2021 Brad Howes. All rights reserved.

import XCTest
@testable import MorkAndMIDI

class UInt32Tests: XCTestCase {

  func testUInt32Bytes() {
    let z = UInt32(0x12_34_56_78)
    XCTAssertEqual(z.byte0, 0x12)
    XCTAssertEqual(z.byte1, 0x34)
    XCTAssertEqual(z.byte2, 0x56)
    XCTAssertEqual(z.byte3, 0x78)
    let y = UInt32(0x41_A3_FF_FF)
    XCTAssertEqual(y.byte0, 0x41)
    XCTAssertEqual(y.byte1, 0xA3)
    XCTAssertEqual(y.byte2, 0xFF)
    XCTAssertEqual(y.byte3, 0xFF)
  }

  func testUInt32Shorts() {
    let z = UInt32(0x12_34_56_78)
    XCTAssertEqual(z.word0, 0x1234)
    XCTAssertEqual(z.word1, 0x5678)
  }
}
