// Copyright © 2023 Brad Howes. All rights reserved.

internal extension UInt8 {

  /// Treat the upper 4 bits as an unsigned 8-bit integer value
  var highNibble: UInt8 { self >> 4}
  /// Treat the lower 4 bits as an unsigned 8-bit integer value
  var lowNibble: UInt8 { self & 0xF }

  /**
   Obtain a bit from the value

   - parameter index: the index of the bit to return, where 0 is the least-significant and 7 is the most significant.
   - returns: true if the bit is set, false otherwise
   */
  subscript(index: Int) -> Bool { (self & (1 << index)) != 0 }

  /// Obtain a hex representation of the value.
  var hex: String { .init(format: "0x%02X", self) }
}
