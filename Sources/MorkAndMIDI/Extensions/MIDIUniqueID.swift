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
    log.debug("boxed - \(self.asHex) -> \(refCon.pointee.asHex) -> \(refCon)")
    return refCon
  }

  /**
   Extract the MIDIUniqueID from a refCon value

   - parameter refCon: raw pointer assumed to originate from `MIDIUniqueID.refCon`
   - returns: the extracted MIDIUniquePtr value
   */
  public static func unbox(_ refCon: UnsafeRawPointer) -> Self {
    let value = refCon.bindMemory(to: Self.self, capacity: 1).pointee
    log.debug("unbox - \(refCon) -> \(value.asHex)")
    return value
  }
}

extension MIDIUniqueID {

  public var asHex: String { String(format: "0x%08X", UInt32(bitPattern: self)) }
}

private let log: Logger = .init(category: "MIDIUniqueID")


extension MIDIEndpointRef {

  public var boxed: UnsafeMutablePointer<MIDIEndpointRef> {
    let refCon = UnsafeMutablePointer<MIDIEndpointRef>.allocate(capacity: 1)
    refCon.initialize(to: self)
    log.debug("boxed - \(self.asHex) -> \(refCon.pointee.asHex) -> \(refCon)")
    return refCon
  }

  public static func unbox(_ refCon: UnsafeRawPointer) -> Self {
    let value = refCon.bindMemory(to: Self.self, capacity: 1).pointee
    log.debug("unbox - \(refCon) -> \(value.asHex)")
    return value
  }

  public var asHex: String { String(format: "0x%08X", self) }
}
