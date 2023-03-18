// Copyright © 2023 Brad Howes. All rights reserved.

import Foundation

internal extension UInt32 {
  var b0: UInt8 { UInt8((self >> 24) & 0xFF)}
  var b1: UInt8 { UInt8((self >> 16) & 0xFF)}
  var b2: UInt8 { UInt8((self >>  8) & 0xFF)}
  var b3: UInt8 { UInt8((self >>  0) & 0xFF)}
  var s0: UInt16 { UInt16((self >> 16) & 0xFFFF)}
  var s1: UInt16 { UInt16((self >>  0) & 0xFFFF)}
}

