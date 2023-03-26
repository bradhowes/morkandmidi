// Copyright © 2023 Brad Howes. All rights reserved.

internal extension UInt32 {
  /// Access the first (most-significant) byte of the integer
  var b0: UInt8 { UInt8((self >> 24) & 0xFF)}
  /// Access second byte of the integer
  var b1: UInt8 { UInt8((self >> 16) & 0xFF)}
  /// Access third byte of the integer
  var b2: UInt8 { UInt8((self >>  8) & 0xFF)}
  /// Access the last (least-significant) byte of the integer
  var b3: UInt8 { UInt8((self >>  0) & 0xFF)}
  /// Access the most-significant short of the integer
  var s0: UInt16 { UInt16((self >> 16) & 0xFFFF)}
  /// Access the least-significant short of the integer
  var s1: UInt16 { UInt16((self >>  0) & 0xFFFF)}
}
