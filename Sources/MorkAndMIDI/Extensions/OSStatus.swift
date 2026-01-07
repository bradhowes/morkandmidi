// Copyright © 2023 Brad Howes. All rights reserved.

import os.log
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

internal extension OSStatus {

  /**
   Log an error if the OSStatus value is not `noErr`.

   - parameter log: the logger to use
   - parameter name: the name of the routine that returned the OSStatus value
   - returns: true if this value is `noErr`
   */
  @discardableResult
  func wasSuccessful(_ log: Logger, _ name: String) -> Bool {
    guard self != noErr else { return true }
    log.error("\(name) - \(self) \(self.tag)")
    return false
  }

  /**
   Log an error if the OSStatus value is not `noErr`.

   - parameter log: the logger to use
   - parameter name: the name of the routine that returned the OSStatus value
   - parameter tag: extra value given to routine name to disambiguate the call site
   - returns: true if this value is `noErr`
   */
  @discardableResult
  func wasSuccessful(_ log: Logger, _ name: String, _ tag: String) -> Bool {
    guard self != noErr else { return true }
    log.error("\(name)(\(tag)) - \(self) \(self.tag)")
    return false
  }
}
