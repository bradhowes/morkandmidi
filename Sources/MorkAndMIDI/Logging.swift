// Copyright © 2021 Brad Howes. All rights reserved.

import os
import Foundation

/// Builder of OSLog values for categorization / classification of log statements.
internal struct Logging {

  /**
   Create a new logger for a subsystem

   - parameter category: the subsystem to log under
   - returns: OSLog instance to use for subsystem logging
   */
  internal static func logger(_ category: String) -> OSLog { OSLog(subsystem: "MorkAndMIDI", category: category) }
}

internal extension OSStatus {

  @discardableResult
  func wasSuccessful(_ log: OSLog, _ name: String) -> Bool {
    guard self != noErr else { return true }
    os_log(.error, log: log, "%{public}s - %d %{public}s", name, self, self.tag)
    return false
  }
}
