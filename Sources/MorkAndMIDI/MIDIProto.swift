//
//  File.swift
//  
//
//  Created by Brad Howes on 09/07/2023.
//

import CoreMIDI

public enum MIDIProto: Int32, @unchecked Sendable {
  case legacy = 0
  case v1_0 = 1
  case v2_0 = 2
}

extension MIDIProto {
  var midiProtocolId: MIDIProtocolID? {
    switch self {
    case .legacy: return nil
    case .v1_0: return ._1_0
    case .v2_0: return ._2_0
    }
  }
}
