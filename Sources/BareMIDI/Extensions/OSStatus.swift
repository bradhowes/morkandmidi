// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI

internal extension OSStatus {

  /// String representations of MIDI OSStatus results
  var tag: String {
    switch self {
    case noErr: return "OK"
    case kMIDIInvalidClient: return "kMIDIInvalidClient"
    case kMIDIInvalidPort: return "kMIDIInvalidPort"
    case kMIDIWrongEndpointType: return "kMIDIWrongEndpointType"
    case kMIDINoConnection: return "kMIDINoConnection"
    case kMIDIUnknownEndpoint: return "kMIDIUnknownEndpoint"
    case kMIDIUnknownProperty: return "kMIDIUnknownProperty"
    case kMIDIWrongPropertyType: return "kMIDIWrongPropertyType"
    case kMIDINoCurrentSetup: return "kMIDINoCurrentSetup"
    case kMIDIMessageSendErr: return "kMIDIMessageSendErr"
    case kMIDIServerStartErr: return "kMIDIServerStartErr"
    case kMIDISetupFormatErr: return "kMIDISetupFormatErr"
    case kMIDIWrongThread: return "kMIDIWrongThread"
    case kMIDIObjectNotFound: return "kMIDIObjectNotFound"
    case kMIDIIDNotUnique: return "kMIDIIDNotUnique"
    case kMIDINotPermitted: return "kMIDINotPermitted"
    default: return "???"
    }
  }
}
