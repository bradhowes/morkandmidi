// Copyright © 2023 Brad Howes. All rights reserved.

import CoreMIDI
import os

extension MIDIObjectRef {

  private var log: OSLog { Logging.logger("MIDIObjectRef") }

  func get(_ property: CFString) -> String {
    var param: Unmanaged<CFString>?
    guard MIDIObjectGetStringProperty(self, property, &param)
      .wasSuccessful(log, "MIDIObjectGetStringProperty", property as String) else { return "" }
    guard let param = param else { return "" }
    return param.takeUnretainedValue() as String
  }

  func set(_ property: CFString, to value: String) {
    _ = MIDIObjectSetStringProperty(self, property, value as CFString)
      .wasSuccessful(log, "MIDIObjectSetStringProperty", property as String)
  }

  func get(_ property: CFString) -> Int32 {
    var param: Int32 = 0
    _ = MIDIObjectGetIntegerProperty(self, property, &param)
      .wasSuccessful(log, "MIDIObjectGetIntegerProperty", property as String)
    return param
  }

  func set(_ property: CFString, to value: Int32) {
    _ = MIDIObjectSetIntegerProperty(self, property, value)
      .wasSuccessful(log, "MIDIObjectSetIntegerProperty", property as String)
  }
}

public extension MIDIObjectRef {
  /// Obtain the product name for a MIDI object.
  var name: String {
    get { get(kMIDIPropertyName) }
    set { set(kMIDIPropertyName, to: newValue)}
  }
  /// Obtain the manufacturer name for a MIDI object.
  var manufacturer: String {
    get { get(kMIDIPropertyManufacturer) }
    set { set(kMIDIPropertyManufacturer, to: newValue)}
  }
  /// Obtain the product name for a MIDI object.
  var model: String {
    get { get(kMIDIPropertyModel) }
    set { set(kMIDIPropertyModel, to: newValue)}
  }
  /// Obtain the display name for a MIDI object. This is
  var displayName: String { return get(kMIDIPropertyDisplayName) }

  /// Obtain the unique ID for a MIDI object
  var uniqueId: MIDIUniqueID {
    get { get(kMIDIPropertyUniqueID) }
    set { set(kMIDIPropertyUniqueID, to: newValue) }
  }
  /// Control the visibility of the endpoint
  var hidden: Bool {
    get { get(kMIDIPropertyPrivate) == 1 }
    set { set(kMIDIPropertyPrivate, to: newValue ? 1 : 0) }
  }
}
