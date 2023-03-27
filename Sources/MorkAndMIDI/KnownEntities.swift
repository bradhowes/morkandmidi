// Copyright © 2023 Brad Howes. All rights reserved.

import CoreMIDI

/**
 Swift collection that dynamically produces known MIDIEndpointRef values depending on the given provider.
 */
internal struct KnownEntityCollection<Provider: KnownEntityProvider>: Collection {
  typealias Index = Int
  typealias Element = MIDIEndpointRef

  var startIndex: Index { 0 }
  var endIndex: Index { Provider.count }

  func index(after index: Index) -> Index { index + 1 }
  subscript (index: Index) -> Element { Provider.get(at: index) }

  static var all: [MIDIEndpointRef] { (0..<Provider.count).map { Provider.get(at: $0) } }
  static func matching(name: String) -> [MIDIEndpointRef] { all.filter { $0.name == name } }
  static func matching(uniqueId: MIDIUniqueID) -> MIDIEndpointRef? { all.first { $0.uniqueId == uniqueId } }
}

extension Collection where Element == MIDIEndpointRef {
  var displayNames: [String] { map { $0.displayName } }
  var uniqueIds: [MIDIUniqueID] { map { $0.uniqueId } }
}

internal typealias KnownSources = KnownEntityCollection<KnownSourcesProvider>
internal typealias KnownDestinations = KnownEntityCollection<KnownDestinationsProvider>

protocol KnownEntityProvider {
  static var count: Int { get }
  static func get(at index: Int) -> MIDIEndpointRef
}

internal struct KnownSourcesProvider: KnownEntityProvider {
  static var count: Int { MIDIGetNumberOfSources() }
  static func get(at index: Int) -> MIDIEndpointRef { MIDIGetSource(index)}
}

internal struct KnownDestinationsProvider: KnownEntityProvider {
  static var count: Int { MIDIGetNumberOfDestinations() }
  static func get(at index: Int) -> MIDIEndpointRef { MIDIGetDestination(index)}
}
