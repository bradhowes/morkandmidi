// Copyright © 2021 Brad Howes. All rights reserved.

import XCTest
@testable import MorkAndMIDI

class UInt8Tests: XCTestCase {

  func testUInt8Nibbles() {
    let z = UInt8(0x3C)
    XCTAssertEqual(z.highNibble, 0x03)
    XCTAssertEqual(z.lowNibble, 0x0C)
  }

  func testUInt8BitAccess() {
    let z = UInt8(0xA5)
    XCTAssertTrue(z[0])
    XCTAssertFalse(z[1])
    XCTAssertTrue(z[2])
    XCTAssertFalse(z[3])
    XCTAssertFalse(z[4])
    XCTAssertTrue(z[5])
    XCTAssertFalse(z[6])
    XCTAssertTrue(z[7])
  }

  func testHexRepresentation() {
    XCTAssertEqual(UInt8(0).hex, "0x00")
    XCTAssertEqual(UInt8(255).hex, "0xFF")
    XCTAssertEqual(UInt8(128).hex, "0x80")
  }
}
