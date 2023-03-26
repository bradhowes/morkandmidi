// Copyright © 2023 Brad Howes. All rights reserved.

import os.log

/// Builder of OSLog values for categorization / classification of log statements.
internal struct Logging {

  /**
   Create a new logger for a subsystem

   - parameter category: the subsystem to log under
   - returns: OSLog instance to use for subsystem logging
   */
  internal static func logger(_ category: String) -> OSLog { OSLog(subsystem: "MorkAndMIDI", category: category) }
}
