// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import OSLog

/// Legacy parser for MIDI 1.0 messages.
class MIDI1Parser {
  private let noReceiver: Int  = -2
  private let allChannels: Int  = -1
  private let midi: MIDI

  init(midi: MIDI) {
    self.midi = midi
  }

  /**
   Extract MIDI messages from the packets and process them

   - parameter source: the unique ID of the MIDI endpoint that sent the messages
   */
  func parse(source: MIDIUniqueID, bytes: MIDIPacket.ByteCollection) {
    let byteCount = bytes.count

    // Uff. In testing with Arturia Minilab mk II, I can sometimes generate packets with zero or really big
    // sizes of 26624 (0x6800!)
    if byteCount == 0 || byteCount > 64 {
      log.error("suspect packet size \(byteCount)")
      return
    }

    log.debug("packet - \(byteCount) bytes")
    processBytes(source: source, bytes: bytes)
  }
}

extension MIDI1Parser {

  private func processBytes(source: MIDIUniqueID, bytes: MIDIPacket.ByteCollection) {
    var index = bytes.startIndex
    while index < bytes.endIndex {
      let status = bytes[index]
      index += 1

      // We have no way to know how to skip over an unknown command, so just ignore rest of packet
      guard let command = MsgKind(status) else { return }

      let needed = command.byteCount
      if acceptsCommand(source: source, status: status, command: command),
         let receiver = midi.receiver,
         index + needed <= bytes.endIndex {
        let channel = command.hasChannel ? UInt8(status & 0x0F) : 0
        dispatch(source: source, command: command, channel: channel, receiver: receiver, bytes: bytes, index: index)
        if command == .systemExclusive {

          // Special case SYSEX because ww do not parse it and so we do not know how many bytes it really needs. We
          // just used 63 in the enum definition.
          return
        }
      }
      index += needed
    }
  }

  private func acceptsCommand(source: MIDIUniqueID, status: UInt8, command: MIDI1Parser.MsgKind) -> Bool {
    guard command.hasChannel else { return true }
    let receiverChannel = midi.receiver?.channel ?? noReceiver
    let packetChannel = Int(status & 0x0F)
    midi.updateEndpointInfo(uniqueId: source, group: -1, channel: packetChannel)
    log.debug("message: \(command.rawValue) packetChannel: \(packetChannel)")
    return receiverChannel == allChannels || receiverChannel == packetChannel
  }

  // swiftlint:disable cyclomatic_complexity

  private func dispatch(source: MIDIUniqueID, command: MIDI1Parser.MsgKind, channel: UInt8, receiver: Receiver,
                bytes: MIDIPacket.ByteCollection, index: Int) {
    func byte0() -> UInt8 { bytes[index] }
    func byte1() -> UInt8 { bytes[index + 1] }
    func word() -> UInt16 { UInt16(byte1()) << 7 + UInt16(byte0()) }

    switch command {
    case .noteOff: receiver.noteOff(source: source, note: byte0(), velocity: byte1(), channel: channel)
    case .noteOn: receiver.noteOn(source: source, note: byte0(), velocity: byte1(), channel: channel)
    case .polyphonicKeyPressure: receiver.polyphonicKeyPressure(source: source, note: byte0(), pressure: byte1(),
                                                                channel: channel)
    case .controlChange: receiver.controlChange(source: source, controller: byte0(), value: byte1(), channel: channel)
    case .programChange: receiver.programChange(source: source, program: byte0(), channel: channel)
    case .channelPressure: receiver.channelPressure(source: source, pressure: byte0(), channel: channel)
    case .pitchBendChange: receiver.pitchBendChange(source: source, value: word(), channel: channel)
    case .systemExclusive: break
    case .timeCodeQuarterFrame: receiver.timeCodeQuarterFrame(source: source, value: byte0())
    case .songPositionPointer: receiver.songPositionPointer(source: source, value: word())
    case .songSelect: receiver.songSelect(source: source, value: byte0())
    case .tuneRequest: receiver.tuneRequest(source: source)
    case .timingClock: receiver.timingClock(source: source)
    case .startCurrentSequence: receiver.startCurrentSequence(source: source)
    case .continueCurrentSequence: receiver.continueCurrentSequence(source: source)
    case .stopCurrentSequence: receiver.stopCurrentSequence(source: source)
    case .activeSensing: receiver.activeSensing(source: source)
    case .reset: receiver.systemReset(source: source)
    }
  }

  // swiftlint:enable cyclomatic_complexity

  /// MIDI commands (v1)
  private enum MsgKind: UInt8 {
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

    /// Number of additional bytes needed by a MIDI command. For now, we ignore system exclusive messages
    var byteCount: Int {
      switch self {
      case .noteOff: return 2
      case .noteOn: return 2
      case .polyphonicKeyPressure: return 2
      case .controlChange: return 2
      case .programChange: return 1
      case .channelPressure: return 1
      case .pitchBendChange: return 2
      case .systemExclusive: return 63 // NOTE: cannot build a MIDIPacket larger than this.
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

private let log: Logger = .init(category: "MIDI1Parser")
