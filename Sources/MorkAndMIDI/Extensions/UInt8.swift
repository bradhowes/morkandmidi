// Copyright © 2023 Brad Howes. All rights reserved.

import Foundation

internal extension UInt8 {
  var nibbles: (high: UInt8, low: UInt8) { (high: self >> 4, low: self & 0xF) }

  subscript(index: Int) -> Bool { (self & (1 << index)) != 0 }
}
