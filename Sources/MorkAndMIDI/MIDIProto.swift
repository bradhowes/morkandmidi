import CoreMIDI

// Support 3 modes of operation:
// - legacy mode that processes MIDI v1 packet lists
// - modern mode that processes MIDI v1 event lists
// - modern mode that processes MIDI v2 event lists
//
public enum MIDIProto: Int32, @unchecked Sendable {
  case legacy = 0
  case v1_0 = 1
  case v2_0 = 2
}

extension MIDIProto {

  /// - returns: `MIDIProtocolID` to use
  var midiProtocolId: MIDIProtocolID? {
    switch self {
    case .legacy: return nil
    case .v1_0: return ._1_0
    case .v2_0: return ._2_0
    }
  }
}
