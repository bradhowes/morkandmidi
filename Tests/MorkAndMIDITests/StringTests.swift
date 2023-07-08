// Copyright © 2021 Brad Howes. All rights reserved.

import XCTest
@testable import MorkAndMIDI

class StringTests: XCTestCase {

  func testOnlyAlphanumerics() {
    XCTAssertEqual("abc123XYZ", "abc123XYZ".onlyAlphaNumerics)
    XCTAssertEqual("abc123XYZ", "abc1.*23XYZ-".onlyAlphaNumerics)
    XCTAssertEqual("abc123XYZ", "abc 123 \n\t XYZ".onlyAlphaNumerics)
    XCTAssertEqual("abc123XYZ", "abc 🥰 123 🧡 XYZ".onlyAlphaNumerics)

    // Diacritics are supported but not symbols
    XCTAssertEqual("abcåbç123XYZ", "abc åbç 123 ¥ XYZ".onlyAlphaNumerics)
  }
}
