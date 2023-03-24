// Copyright © 2023 Brad Howes. All rights reserved.

import Foundation

internal extension UInt8 {
  var highNibble: UInt8 { self >> 4}
  var lowNibble: UInt8 { self & 0xF }

  subscript(index: Int) -> Bool { (self & (1 << index)) != 0 }
}
