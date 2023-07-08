// Copyright © 2023 Brad Howes. All rights reserved.

import CoreMIDI
import os

internal extension MIDIUniqueID {

  var boxed: UnsafeMutablePointer<MIDIUniqueID> {
    let refCon = UnsafeMutablePointer<MIDIUniqueID>.allocate(capacity: 1)
    refCon.initialize(to: self)
    return refCon
  }

  static func unbox(_ refCon: UnsafeRawPointer?) -> MIDIUniqueID? {
    refCon?.assumingMemoryBound(to: MIDIUniqueID.self).pointee
  }
}
