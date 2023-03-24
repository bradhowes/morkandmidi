// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import os

internal extension MIDIObjectRef {

  private var log: OSLog { Logging.logger("MIDIObjectRef") }

  /// Obtain the display name for a MIDI object. If not defined, return "nil"
  var displayName: String {
    var param: Unmanaged<CFString>?
    let failed = MIDIObjectGetStringProperty(self, kMIDIPropertyDisplayName, &param)
      .wasSuccessful(log, "MIDIObjectGetStringProperty(kMIDIPropertyDisplayName)")
    return failed ? "nil" : param!.takeUnretainedValue() as String
  }

  /// Obtain the unique ID for a MIDI object
  var uniqueId: MIDIUniqueID {
    var param: MIDIUniqueID = MIDIUniqueID()
    MIDIObjectGetIntegerProperty(self, kMIDIPropertyUniqueID, &param)
      .wasSuccessful(log, "MIDIObjectGetIntegerProperty(kMIDIPropertyUniqueID)")
    return param
  }
}
