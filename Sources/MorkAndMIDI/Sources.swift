// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI

/**
 Swift collection that dynamically produces known MIDIEndpointRef values.
 */
internal struct Sources: Collection {
  typealias Index = Int
  typealias Element = MIDIEndpointRef

  var startIndex: Index { 0 }
  var endIndex: Index { MIDIGetNumberOfSources() }

  var displayNames: [String] { map { $0.displayName } }
  var uniqueIds: [MIDIUniqueID] { map { $0.uniqueId } }

  init() {}

  func index(after index: Index) -> Index { index + 1 }
  subscript (index: Index) -> Element { MIDIGetSource(index) }
}
