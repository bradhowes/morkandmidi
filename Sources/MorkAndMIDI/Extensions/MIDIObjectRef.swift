// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import os

internal extension MIDIObjectRef {

  private var log: OSLog { Logging.logger("MIDIObjectRef") }

  /// Obtain the display name for a MIDI object. If not defined, return "nil"
  var displayName: String {
    var param: Unmanaged<CFString>?
    let failed = logIfErr(log, "MIDIObjectGetStringProperty(kMIDIPropertyDisplayName)",
                        MIDIObjectGetStringProperty(self, kMIDIPropertyDisplayName, &param))
    return failed ? "nil" : param!.takeUnretainedValue() as String
  }

  /// Obtain the unique ID for a MIDI object
  var uniqueId: MIDIUniqueID {
    var param: MIDIUniqueID = MIDIUniqueID()
    logIfErr(log, "MIDIObjectGetIntegerProperty(kMIDIPropertyUniqueID)",
           MIDIObjectGetIntegerProperty(self, kMIDIPropertyUniqueID, &param))
    return param
  }
}
