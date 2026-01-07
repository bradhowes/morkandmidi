// Copyright © 2023-2026 Brad Howes. All rights reserved.

import CoreMIDI

extension MIDIUniqueID {

  /**
   Allocate storage for MIDIUniqueID and return to use as a `refCon` parameter in MIDI API calls.
   - returns: pointer to memory holding the MIDIUniqueID value
   */
  public var boxed: UnsafeMutablePointer<MIDIUniqueID> {
    let refCon = UnsafeMutablePointer<MIDIUniqueID>.allocate(capacity: 1)
    refCon.initialize(to: self)
    return refCon
  }

  /**
   Extract the MIDIUniqueID from a refCon value

   - parameter refCon: optional raw pointer assumed to originate from `MIDIUniqueID.refCon`
   - returns: the extracted MIDIUniquePtr if `refCon` exists
   */
  public static func unbox(_ refCon: UnsafeRawPointer?) -> MIDIUniqueID? {
    refCon?.assumingMemoryBound(to: MIDIUniqueID.self).pointee
  }
}

extension MIDIUniqueID {

  public var asHex: String { String(format: "0x%08X", UInt32(bitPattern: self)) }
}
