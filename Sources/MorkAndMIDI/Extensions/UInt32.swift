// Copyright © 2023 Brad Howes. All rights reserved.

public extension UInt32 {
  /// Access the first (most-significant) byte of the integer
  var byte0: UInt8 { UInt8((self >> 24) & 0xFF)}
  /// Access second byte of the integer
  var byte1: UInt8 { UInt8((self >> 16) & 0xFF)}
  /// Access third byte of the integer
  var byte2: UInt8 { UInt8((self >>  8) & 0xFF)}
  /// Access the last (least-significant) byte of the integer
  var byte3: UInt8 { UInt8((self >>  0) & 0xFF)}
  /// Access the most-significant short of the integer
  var word0: UInt16 { UInt16((self >> 16) & 0xFFFF)}
  /// Access the least-significant short of the integer
  var word1: UInt16 { UInt16((self >>  0) & 0xFFFF)}
}
