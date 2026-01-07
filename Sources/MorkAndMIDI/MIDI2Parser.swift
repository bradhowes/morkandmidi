// Copyright © 2023-2026 Brad Howes. All rights reserved.

import CoreMIDI
import OSLog

/**
 Parser of Universal MIDI Packet (v2 of MIDI spec)
 */
public struct MIDI2Parser {
  private let allChannelGroupFilter = -1
  private let neverChannelGroupFilter = -2

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

    static func from(word: UInt32) -> UniversalMessageType? { .init(rawValue: word.byte0.highNibble) }
  }

  /// MIDI commands (v1 and v2)
  enum ChannelVoiceMessage: UInt8 {
    case registeredPerNoteControllerChange = 0
    case assignablePerNoteControllerChange = 1
    case registeredControllerChange = 2
    case assignableControllerChange = 3
    case relativeRegisteredControllerChange = 4
    case relativeAssignableControllerChange = 5
    case perNotePitchBendChange = 6
    case noteOff = 8
    case noteOn = 9
    case polyphonicKeyPressure = 10
    case controlChange = 11
    case programChange = 12
    case channelPressure = 13
    case pitchBendChange = 14
    case perNoteManagement = 15

    static func from(word: UInt32) -> ChannelVoiceMessage? { .init(rawValue: word.byte1.highNibble) }
    static func channel(word: UInt32) -> UInt8 { word.byte1.lowNibble }
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

    static func from(word: UInt32) -> SystemCommonAndRealTimeMessage? { .init(rawValue: word.byte1) }
  }

  private let midi: MIDI

  init(midi: MIDI) {
    self.midi = midi
  }
}

// swiftlint:disable cyclomatic_complexity

public extension MIDI2Parser {

  /**
   Extract MIDI messages from the packets and process them

   - parameter midi: controller of MIDI processing
   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the messages
   */
  func parse(source: MIDIUniqueID, words: MIDIEventPacket.WordCollection) {
    let receiver = midi.receiver
    let receiverGroup = receiver?.group ?? neverChannelGroupFilter
    let receiverChannel = receiver?.channel ?? neverChannelGroupFilter

    func acceptsMessage(_ word: UInt32) -> Receiver? {
      let messageGroup = Int(word.byte0.lowNibble)
      let messageChannel = Int(word.byte1.lowNibble)
      midi.updateEndpointInfo(uniqueId: source, group: messageGroup, channel: messageChannel)
      return ((receiverGroup == allChannelGroupFilter || receiverGroup == messageGroup) &&
              (receiverChannel == allChannelGroupFilter || receiverChannel == messageChannel)) ? midi.receiver : nil
    }

    var index = words.startIndex
    while index < words.endIndex {
      let word0 = words[index]

      guard let messageType = UniversalMessageType.from(word: word0) else {
        log.error("invalid UniversalMessageType - \(word0)")
        return
      }

      switch messageType {
      case .utility: log.debug("skipping utility messages")
      case .systemCommonAndRealTime:
        if let receiver = receiver {
          dispatchSystemCommandAndRealTime(receiver: receiver, source: source, data: word0)
        }
      case .midi1ChannelVoice:
        if let receiver = acceptsMessage(word0) {
          dispatchMIDI1Message(receiver: receiver, source: source, data: word0)
        }
      case .data64bit: log.debug("skipping data64bit messages")
      case .midi2ChannelVoice:
        if let receiver = acceptsMessage(word0) {
          let word1 = words[index.advanced(by: 1)]
          dispatchMIDI2Message(receiver: receiver, source: source, data1: word0, data2: word1)
        }
      case .data128bit: log.debug("skipping data128bit messages")
      }

      index = index.advanced(by: messageType.wordCount)
    }
  }
}

private extension MIDI2Parser {
  func toMidi1Word(value: UInt32) -> UInt16 { UInt16(value.byte3) << 7 + UInt16(value.byte2) }

  func dispatchSystemCommandAndRealTime(receiver: Receiver, source: MIDIUniqueID, data: UInt32) {
    switch SystemCommonAndRealTimeMessage.from(word: data) {
    case .timeCodeQuarterFrame: receiver.timeCodeQuarterFrame(source: source, value: data.byte2)
    case .songPositionPointer: receiver.songPositionPointer(source: source, value: toMidi1Word(value: data))
    case .songSelect: receiver.songSelect(source: source, value: data.byte2)
    case .tuneRequest: receiver.tuneRequest(source: source)
    case .timingClock:  receiver.timingClock(source: source)
    case .startCurrentSequence: receiver.startCurrentSequence(source: source)
    case .continueCurrentSequence: receiver.continueCurrentSequence(source: source)
    case .stopCurrentSequence: receiver.stopCurrentSequence(source: source)
    case .activeSensing: receiver.activeSensing(source: source)
    case .reset: receiver.systemReset(source: source)
    case nil: log.error("invalid SystemCommonAndRealTimeMessage - \(data)")
    }
  }

  func dispatchMIDI1Message(receiver: Receiver, source: MIDIUniqueID, data: UInt32) {
    let channel = ChannelVoiceMessage.channel(word: data)
    switch ChannelVoiceMessage.from(word: data) {
    case .noteOff: receiver.noteOff(source: source, note: data.byte2, velocity: data.byte3, channel: channel)
    case .noteOn: receiver.noteOn(source: source, note: data.byte2, velocity: data.byte3, channel: channel)
    case .polyphonicKeyPressure: receiver.polyphonicKeyPressure(source: source, note: data.byte2, pressure: data.byte3,
                                                                channel: channel)
    case .controlChange: receiver.controlChange(source: source, controller: data.byte2, value: data.byte3,
                                                channel: channel)
    case .programChange: receiver.programChange(source: source, program: data.byte2, channel: channel)
    case .channelPressure: receiver.channelPressure(source: source, pressure: data.byte2, channel: channel)
    case .pitchBendChange: receiver.pitchBendChange(source: source, value: toMidi1Word(value: data), channel: channel)
    default: log.error("invalid ChannelVoiceMessage for midi1CHannelVoice - \(data)")
    }
  }

  func dispatchMIDI2Message(receiver: Receiver, source: MIDIUniqueID, data1: UInt32, data2: UInt32) {
    func toInt32(value: UInt32) -> Int32 { .init(bitPattern: value) }
    let channel = ChannelVoiceMessage.channel(word: data1)
    switch ChannelVoiceMessage.from(word: data1) {
    case .registeredPerNoteControllerChange: receiver.registeredPerNoteControllerChange(source: source,
                                                                                        note: data1.byte2,
                                                                                        controller: data1.byte3,
                                                                                        value: data2)
    case .assignablePerNoteControllerChange: receiver.assignablePerNoteControllerChange(source: source,
                                                                                        note: data1.byte2,
                                                                                        controller: data1.byte3,
                                                                                        value: data2)
    case .registeredControllerChange: receiver.registeredControllerChange(source: source, controller: data1.word1,
                                                                          value: data2)
    case .assignableControllerChange: receiver.assignableControllerChange(source: source, controller: data1.word1,
                                                                          value: data2)
    case .relativeRegisteredControllerChange: receiver.relativeRegisteredControllerChange(source: source,
                                                                                          controller: data1.word1,
                                                                                          value: toInt32(value: data2))
    case .relativeAssignableControllerChange: receiver.relativeAssignableControllerChange(source: source,
                                                                                          controller: data1.word1,
                                                                                          value: toInt32(value: data2))
    case .perNotePitchBendChange: receiver.perNotePitchBendChange(source: source, note: data1.byte2, value: data2)
    case .noteOff: receiver.noteOff2(source: source, note: data1.byte2, velocity: data2.word0, channel: channel,
                                     attributeType: data1.byte3, attributeData: data2.word1)
    case .noteOn: receiver.noteOn2(source: source, note: data1.byte2, velocity: data2.word0, channel: channel,
                                   attributeType: data1.byte3, attributeData: data2.word1)
    case .polyphonicKeyPressure: receiver.polyphonicKeyPressure2(source: source, note: data1.byte2, pressure: data2,
                                                                 channel: channel)
    case .controlChange: receiver.controlChange2(source: source, controller: data1.byte2, value: data2,
                                                 channel: channel)
    case .programChange:
      if data1.byte3[0] {
        receiver.programChange2(source: source, program: data2.byte0, bank: data2.word1, channel: channel)
      } else {
        receiver.programChange(source: source, program: data2.byte0, channel: channel)
      }
    case .channelPressure: receiver.channelPressure2(source: source, pressure: data2, channel: channel)
    case .pitchBendChange: receiver.pitchBendChange2(source: source, value: data2, channel: channel)
    case .perNoteManagement: receiver.perNoteManagement(source: source, note: data1.byte2, detach: data1.byte3[1],
                                                        reset: data1.byte3[0])
    case nil: log.error("invalid ChannelVoiceMessage - \(data1)")
    }
  }
}
// swiftlint:enable cyclomatic_complexity

private let log: Logger = .init(category: "MIDI2Parsser")
