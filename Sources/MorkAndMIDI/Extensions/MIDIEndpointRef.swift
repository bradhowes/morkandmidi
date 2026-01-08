// Copyright © 2023-2026 Brad Howes. All rights reserved.

import CoreMIDI
import os

extension MIDIEndpointRef {

  public var logInfo: String {
    "<MIDIEndpointRef \(self) - uniqueId: \(self.uniqueId.asHex) name: \(self.displayName)>"
  }
}
