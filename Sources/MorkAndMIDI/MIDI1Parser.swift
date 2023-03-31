// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import os.log

/// Legacy parser for MIDI 1.0 messages. This is not currently used as MIDI 2.0 Universal MIDI Packet (UMP) messages
/// can handle MIDI 1.0 layout.
internal class MIDI1Parser {
  private var log: OSLog { Logging.logger("MIDI1Parser") }

  /**
   Extract MIDI messages from the packets and process them

   - parameter midi: controller of MIDI processing
   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the messages
   */
  func parse(midi: MIDI, uniqueId: MIDIUniqueID, bytes: MIDIPacket.ByteCollection) {
    let byteCount = bytes.count

    // Uff. In testing with Arturia Minilab mk II, I can sometimes generate packets with zero or really big
    // sizes of 26624 (0x6800!)
    if byteCount == 0 || byteCount > 64 {
      os_log(.error, log: log, "suspect packet size %d", byteCount)
      return
    }

    os_log(.debug, log: log, "packet - %d bytes", byteCount)

    let receiverChannel = midi.receiver?.channel ?? -2

    // Visit the individual bytes until all consumed. If there is something we don't understand, we stop processing the
    // packet.
    var index = bytes.startIndex
    while index < bytes.endIndex {
      let status = bytes[index]
      index += 1

      // We have no way to know how to skip over an unknown command, so just ignore rest of packet
      guard let command = MsgKind(status) else { return }

      let needed = command.byteCount

      if command.hasChannel {
        let packetChannel = Int(status & 0x0F)

        // We have enough information to update the channel that an endpoint is sending on
        midi.updateEndpointInfo(uniqueId: uniqueId, group: -1, channel: packetChannel)

        os_log(.debug, log: log, "message: %d packetChannel: %d", command.rawValue, packetChannel)

        if receiverChannel != -1 && receiverChannel != packetChannel {
          index += needed
          continue
        }
      }

      // Filter out messages if they come on a channel we are not listening, or we do not have enough bytes to continue
      guard let receiver = midi.receiver, index + needed <= bytes.endIndex else {
        index += needed
        continue
      }

      switch command {
      case .noteOff: receiver.noteOff(note: bytes[index], velocity: bytes[index + 1])
      case .noteOn: receiver.noteOn(note: bytes[index], velocity: bytes[index + 1])
      case .polyphonicKeyPressure: receiver.polyphonicKeyPressure(note: bytes[index], pressure: bytes[index + 1])
      case .controlChange: receiver.controlChange(controller: bytes[index], value: bytes[index + 1])
      case .programChange: receiver.programChange(program: bytes[index])
      case .channelPressure: receiver.channelPressure(pressure: bytes[index])
      case .pitchBendChange: receiver.pitchBendChange(value: UInt16(bytes[index + 1]) << 7 + UInt16(bytes[index]))
      case .systemExclusive: break
      case .timeCodeQuarterFrame: receiver.timeCodeQuarterFrame(value: bytes[index])
      case .songPositionPointer: receiver.songPositionPointer(value: UInt16(bytes[index + 1]) << 7 + UInt16(bytes[index]))
      case .songSelect: receiver.songSelect(value: bytes[index])
      case .tuneRequest: receiver.tuneRequest()
      case .timingClock: receiver.timingClock()
      case .startCurrentSequence: receiver.startCurrentSequence()
      case .continueCurrentSequence: receiver.continueCurrentSequence()
      case .stopCurrentSequence: receiver.stopCurrentSequence()
      case .activeSensing: receiver.activeSensing()
      case .reset: receiver.systemReset()
      }

      index += needed
    }
  }

  /// MIDI commands (v1)
  enum MsgKind: UInt8 {
    case noteOff = 0x80
    case noteOn = 0x90
    case polyphonicKeyPressure = 0xA0
    case controlChange = 0xB0
    case programChange = 0xC0
    case channelPressure = 0xD0
    case pitchBendChange = 0xE0
    case systemExclusive = 0xF0
    case timeCodeQuarterFrame = 0xF1
    case songPositionPointer = 0xF2
    case songSelect = 0xF3
    case tuneRequest = 0xF6
    case timingClock = 0xF8
    case startCurrentSequence = 0xFA
    case continueCurrentSequence = 0xFB
    case stopCurrentSequence = 0xFC
    case activeSensing = 0xFE
    case reset = 0xFF

    /**
     Attempt to convert a byte into a MIDI command.

     - parameter raw: the byte to use
     */
    init?(_ raw: UInt8) {
      // Commands starting at 0xF0 require the whole byte, not just the upper 4 bits.
      let highNibble = raw & 0xF0
      self.init(rawValue: highNibble == 0xF0 ? raw : highNibble)
    }

    /// True if MIDI message has channel
    var hasChannel: Bool { self.rawValue < 0xF0 }

    /// Number of additional bytes needed by a MIDI command. For systemExclusive, set to very large value in order to
    /// stop parsing of the MIDIPacket since we don't support systemExclusive messages.
    var byteCount: Int {
      switch self {
      case .noteOff: return 2
      case .noteOn: return 2
      case .polyphonicKeyPressure: return 2
      case .controlChange: return 2
      case .programChange: return 1
      case .channelPressure: return 1
      case .pitchBendChange: return 2
      case .systemExclusive: return 63
      case .timeCodeQuarterFrame: return 1
      case .songPositionPointer: return 2
      case .songSelect: return 1
      case .tuneRequest: return 0
      case .timingClock: return 0
      case .startCurrentSequence: return 0
      case .continueCurrentSequence: return 0
      case .stopCurrentSequence: return 0
      case .activeSensing: return 0
      case .reset: return 0
      }
    }
  }
}
