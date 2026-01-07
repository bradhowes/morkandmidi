// Copyright © 2023 Brad Howes. All rights reserved.

import Foundation

internal extension String {

  /// - returns: new value with only alpha-numeric characters remaining
  var onlyAlphaNumerics: String {
    unicodeScalars
      .filter { CharacterSet.alphanumerics.contains($0) }
      .map { "\($0)" }
      .joined()
  }
}
