// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import os

/**
 Parser of Universal MIDI Packet
 */
public struct MIDI2Parser {
  private var log: OSLog { Logging.logger("MIDI2Parser") }

  // From M2-104-UM Universal MIDI Packet (UMP) Format and MIDI 2.0 Protocol Appendix G
  enum UniversalMessageType: UInt8 {
    case utility = 0
    case systemCommonAndRealTime = 1
    case midi1ChannelVoice = 2
    case data64bit = 3
    case midi2ChannelVoice = 4
    case data128bit = 5

    var wordCount: Int {
      switch self {
      case .utility: return 1
      case .systemCommonAndRealTime: return 1
      case .midi1ChannelVoice: return 1
      case .data64bit: return 2
      case .midi2ChannelVoice: return 2
      case .data128bit: return 4
      }
    }

    static func from(word: UInt32) -> UniversalMessageType? { .init(rawValue: word.b0.nibbles.high) }
  }

  /// MIDI commands (v1 and v2)
  enum ChannelVoiceMessage: UInt8 {
    case registeredPerNoteControllerChange = 0
    case assignablePerNoteControllerChange = 1
    case registeredControllerChange = 2
    case assignableControllerChange = 3
    case relativeRegisteredControllerChange = 4
    case relativeAssignableControllerChange = 5
    case noteOff = 8
    case noteOn = 9
    case polyphonicKeyPressure = 10
    case controlChange = 11
    case programChange = 12
    case channelPressure = 13
    case pitchBendChange = 14
    case perNoteManagement = 15

    static func from(word: UInt32) -> ChannelVoiceMessage? { .init(rawValue: word.b1.nibbles.high) }
  }

  enum SystemCommonAndRealTimeMessage: UInt8 {
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

    static func from(word: UInt32) -> SystemCommonAndRealTimeMessage? { .init(rawValue: word.b1) }
  }
}

public extension MIDI2Parser {

  /**
   Extract MIDI messages from the packets and process them

   - parameter midi: controller of MIDI processing
   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the messages
   */
  func parse(midi: MIDI, uniqueId: MIDIUniqueID, words: MIDIEventPacket.WordCollection) {
    let receiverChannel = midi.receiver?.channel ?? -2

    func acceptsMessageChannel(_ word: UInt32) -> Bool {
      let messageChannel = Int(word.b1.nibbles.low)
      midi.updateEndpointChannel(uniqueId: uniqueId, channel: messageChannel)
      midi.monitor?.seen(uniqueId: uniqueId, channel: messageChannel)
      return receiverChannel == -1 || receiverChannel == messageChannel
    }

    func toMidi1Word(msb: UInt8, lsb: UInt8) -> UInt16 { UInt16(msb) << 7 + UInt16(lsb) }

    var index = words.startIndex
    while index < words.endIndex {
      let word0 = words[index]

      guard let messageType = UniversalMessageType.from(word: word0) else {
        os_log(.error, log: log, "invalid UniversalMessageType - %d", word0)
        return
      }

      switch messageType {
      case .utility:
        // This contains NOOP and jitter reduction messages -- ignored
        os_log(.debug, log: log, "skipping utility messages")
        break

      case .systemCommonAndRealTime:
        switch SystemCommonAndRealTimeMessage.from(word: word0)  {
        case .timeCodeQuarterFrame:
          midi.receiver!.timeCodeQuarterFrame(value: word0.b2)
        case .songPositionPointer:
          midi.receiver!.songPositionPointer(value: toMidi1Word(msb: word0.b3, lsb: word0.b2))
        case .songSelect:
          midi.receiver!.songSelect(value: word0.b2)
        case .tuneRequest:
          midi.receiver!.tuneRequest()
        case .timingClock:
          midi.receiver!.timingClock()
        case .startCurrentSequence:
          midi.receiver!.startCurrentSequence()
        case .continueCurrentSequence:
          midi.receiver!.continueCurrentSequence()
        case .stopCurrentSequence:
          midi.receiver!.stopCurrentSequence()
        case .activeSensing:
          midi.receiver!.activeSensing()
        case .reset:
          midi.receiver!.reset()
        case nil:
          os_log(.error, log: log, "invalid SystemCommonAndRealTimeMessage - %d", word0)
        }
      case .midi1ChannelVoice:
        if acceptsMessageChannel(word0) {
          switch ChannelVoiceMessage.from(word: word0)  {
          case .registeredPerNoteControllerChange:
            os_log(.error, log: log, "invalid ChannelVoiceMessage for midi1CHannelVoice - %d", word0)
          case .assignablePerNoteControllerChange:
            os_log(.error, log: log, "invalid ChannelVoiceMessage for midi1CHannelVoice - %d", word0)
          case .registeredControllerChange:
            os_log(.error, log: log, "invalid ChannelVoiceMessage for midi1CHannelVoice - %d", word0)
          case .assignableControllerChange:
            os_log(.error, log: log, "invalid ChannelVoiceMessage for midi1CHannelVoice - %d", word0)
          case .relativeRegisteredControllerChange:
            os_log(.error, log: log, "invalid ChannelVoiceMessage for midi1CHannelVoice - %d", word0)
          case .relativeAssignableControllerChange:
            os_log(.error, log: log, "invalid ChannelVoiceMessage for midi1CHannelVoice - %d", word0)
          case .noteOff:
            midi.receiver!.noteOff(note: word0.b2, velocity: word0.b3)
          case .noteOn:
            midi.receiver!.noteOn(note: word0.b2, velocity: word0.b3)
          case .polyphonicKeyPressure:
            midi.receiver!.polyphonicKeyPressure(note: word0.b2, pressure: word0.b3)
          case .controlChange:
            midi.receiver!.controlChange(controller: word0.b2, value: word0.b3)
          case .programChange:
            midi.receiver!.programChange(program: word0.b2)
          case .channelPressure:
            midi.receiver!.channelPressure(pressure: word0.b2)
          case .pitchBendChange:
            midi.receiver!.pitchBendChange(value: toMidi1Word(msb: word0.b3, lsb: word0.b2))
          case .perNoteManagement:
            os_log(.error, log: log, "invalid ChannelVoiceMessage for midi1CHannelVoice - %d", word0)
          case nil:
            os_log(.error, log: log, "invalid ChannelVoiceMessage - %d", word0)
          }
        }
      case .data64bit:
        os_log(.debug, log: log, "skipping data64bit messages")
      case .midi2ChannelVoice:
        if acceptsMessageChannel(word0) {
          let word1 = words[index.advanced(by: 1)]
          switch ChannelVoiceMessage.from(word: word0)  {
          case .registeredPerNoteControllerChange:
            midi.receiver!.registeredPerNoteControllerChange(note: word0.b2, controller: word0.b3, value: word1)
          case .assignablePerNoteControllerChange:
            midi.receiver!.assignablePerNoteControllerChange(note: word0.b2, controller: word0.b3, value: word1)
          case .registeredControllerChange:
            midi.receiver!.registeredControllerChange(controller: word0.s1, value: word1)
          case .assignableControllerChange:
            midi.receiver!.assignableControllerChange(controller: word0.s1, value: word1)
          case .relativeRegisteredControllerChange:
            midi.receiver!.relativeRegisteredControllerChange(controller: word0.s1, value: Int32(bitPattern: word1))
          case .relativeAssignableControllerChange:
            midi.receiver!.relativeAssignableControllerChange(controller: word0.s1, value: Int32(bitPattern: word1))
          case .noteOff:
            midi.receiver!.noteOff2(note: word0.b2, velocity: word1.s0, attributeType: word0.b3, attributeData: word1.s1)
          case .noteOn:
            midi.receiver!.noteOn2(note: word0.b2, velocity: word1.s0, attributeType: word0.b3, attributeData: word1.s1)
          case .polyphonicKeyPressure:
            midi.receiver!.polyphonicKeyPressure2(note: word0.b2, pressure: word1)
          case .controlChange:
            midi.receiver!.controlChange2(controller: word0.b2, value: word1)
          case .programChange:
            if word0.b3[0] {
              midi.receiver!.programChange2(program: word1.b0, bank: word1.s1)
            } else {
              midi.receiver!.programChange(program: word1.b0)
            }
          case .channelPressure:
            midi.receiver!.channelPressure2(pressure: word1)
          case .pitchBendChange:
            midi.receiver!.pitchBendChange2(value: word1)
          case .perNoteManagement:
            midi.receiver!.perNoteManagement(note: word0.b2, detach: word0.b3[1], reset: word0.b3[0])
          case nil:
            os_log(.error, log: log, "invalid ChannelVoiceMessage - %d", word0)
          }
        }
      case .data128bit:
        os_log(.debug, log: log, "skipping data128bit messages")
      }
      index = index.advanced(by: messageType.wordCount)
    }
  }
}
