// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import XCTest
@testable import MorkAndMIDI

class MIDI2ParserTests: XCTestCase {

  var receiver: Receiver!
  var midi: MIDI!
  var packetBuilder: MIDIEventPacket.Builder!
  var parser: MIDI2Parser!

  override func setUp() {
    super.setUp()
    receiver = .init(self)
    midi = MIDI(clientName: "midi2parserTests", uniqueId: 123)
    midi.receiver = receiver
    packetBuilder = MIDIEventPacket.Builder(maximumNumberMIDIWords: 64)
    packetBuilder.timeStamp = 0
    parser = MIDI2Parser()
  }

  override func tearDown() {
    midi = nil
    super.tearDown()
  }

  func testUniversalMessageType() {
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x01_23_45_67)), .utility)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x11_23_45_67)), .systemCommonAndRealTime)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x21_23_45_67)), .midi1ChannelVoice)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x31_23_45_67)), .data64bit)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x41_23_45_67)), .midi2ChannelVoice)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x51_23_45_67)), .data128bit)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x61_23_45_67)), nil)
  }

  func testUniversalMessageTypeWordCount() {
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x01_23_45_67))?.wordCount, 1)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x11_23_45_67))?.wordCount, 1)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x21_23_45_67))?.wordCount, 1)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x31_23_45_67))?.wordCount, 2)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x41_23_45_67))?.wordCount, 2)
    XCTAssertEqual(MIDI2Parser.UniversalMessageType.from(word: UInt32(0x51_23_45_67))?.wordCount, 4)
  }

  func testChanneVoiceMessage() {
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_03_45_67)), .registeredPerNoteControllerChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_13_45_67)), .assignablePerNoteControllerChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_23_45_67)), .registeredControllerChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_33_45_67)), .assignableControllerChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_43_45_67)), .relativeRegisteredControllerChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_53_45_67)), .relativeAssignableControllerChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_63_45_67)), .perNotePitchBendChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_73_45_67)), nil)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_83_45_67)), .noteOff)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_93_45_67)), .noteOn)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_A3_45_67)), .polyphonicKeyPressure)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_B3_45_67)), .controlChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_C3_45_67)), .programChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_D3_45_67)), .channelPressure)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_E3_45_67)), .pitchBendChange)
    XCTAssertEqual(MIDI2Parser.ChannelVoiceMessage.from(word: UInt32(0x01_F3_45_67)), .perNoteManagement)
  }

  func testSystemCommonAndRealTimeMessage() {
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F0_45_67)), nil)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F1_45_67)), .timeCodeQuarterFrame)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F2_45_67)), .songPositionPointer)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F3_45_67)), .songSelect)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F4_45_67)), nil)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F5_45_67)), nil)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F6_45_67)), .tuneRequest)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F7_45_67)), nil)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F8_45_67)), .timingClock)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_F9_45_67)), nil)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_FA_45_67)), .startCurrentSequence)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_FB_45_67)), .continueCurrentSequence)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_FC_45_67)), .stopCurrentSequence)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_FD_45_67)), nil)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_FE_45_67)), .activeSensing)
    XCTAssertEqual(MIDI2Parser.SystemCommonAndRealTimeMessage.from(word: UInt32(0x01_FF_45_67)), .reset)
  }

  func testParserIgnoresUnsupportedMessageTypes() {
    packetBuilder.append(UInt32(0x01_23_45_67))
    packetBuilder.append(UInt32(0x11_23_45_67))
    packetBuilder.append(UInt32(0x21_00_01_02))
    packetBuilder.append(UInt32(0x21_10_01_02))
    packetBuilder.append(UInt32(0x21_20_01_02))
    packetBuilder.append(UInt32(0x21_30_01_02))
    packetBuilder.append(UInt32(0x21_40_01_02))
    packetBuilder.append(UInt32(0x21_50_01_02))
    packetBuilder.append(UInt32(0x21_63_45_67), UInt32(0x00))
    packetBuilder.append(UInt32(0x21_71_01_02))
    packetBuilder.append(UInt32(0x21_81_01_02))
    packetBuilder.append(UInt32(0x21_F1_01_02))
    packetBuilder.append(UInt32(0x31_23_45_67))
    packetBuilder.append(UInt32(0x41_23_45_67))
    packetBuilder.append(UInt32(0x41_71_01_02), UInt32(0x00))
    packetBuilder.append(UInt32(0x51_23_45_67), UInt32(0x00), UInt32(0x00), UInt32(0x00))
    packetBuilder.append(UInt32(0x61_81_01_02))
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
    XCTAssertEqual(receiver.received.count, 1)
  }

  func testParsingMIDI1ChannelVoiceMessages() {
    packetBuilder.append(UInt32(0x21_81_01_02))
    packetBuilder.append(UInt32(0x21_92_03_04))
    packetBuilder.append(UInt32(0x21_A3_05_06))
    packetBuilder.append(UInt32(0x21_B4_07_08))
    packetBuilder.append(UInt32(0x21_C5_09_0A))
    packetBuilder.append(UInt32(0x21_D6_0B_0C))
    packetBuilder.append(UInt32(0x21_E7_0D_0E))
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
    XCTAssertEqual(7, receiver.received.count)
    XCTAssertEqual(receiver.received[0], "noteOff 1 2")
    XCTAssertEqual(receiver.received[1], "noteOn 3 4")
    XCTAssertEqual(receiver.received[2], "polyphonicKeyPressure 5 6")
    XCTAssertEqual(receiver.received[3], "controlChange 7 8")
    XCTAssertEqual(receiver.received[4], "programChange 9")
    XCTAssertEqual(receiver.received[5], "channelPressure 11")
    XCTAssertEqual(receiver.received[6], "pitchBendChange 1805")
  }

  func testParserIgnoresMessageIfGroupMismatch() {
    receiver.group = 1
    packetBuilder.append(UInt32(0x21_81_01_02))
    packetBuilder.append(UInt32(0x11_92_01_02))
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
    XCTAssertEqual(1, receiver.received.count)
    XCTAssertEqual(receiver.received[0], "noteOff 1 2")
  }

  func testParserIgnoresMessageIfChannelMismatch() {
    receiver.channel = 1
    packetBuilder.append(UInt32(0x21_81_01_02))
    packetBuilder.append(UInt32(0x21_92_01_02))
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
    XCTAssertEqual(1, receiver.received.count)
    XCTAssertEqual(receiver.received[0], "noteOff 1 2")
  }

  func testParsingMIDI1SystemMessages() {
    packetBuilder.append(UInt32(0x10_F1_01_02))
    packetBuilder.append(UInt32(0x10_F2_03_04))
    packetBuilder.append(UInt32(0x10_F3_05_06))
    packetBuilder.append(UInt32(0x10_F6_07_08))
    packetBuilder.append(UInt32(0x10_F8_09_0A))
    packetBuilder.append(UInt32(0x10_FA_0B_0C))
    packetBuilder.append(UInt32(0x10_FB_0D_0E))
    packetBuilder.append(UInt32(0x10_FC_0F_10))
    packetBuilder.append(UInt32(0x10_FD_13_14)) // Invalid
    packetBuilder.append(UInt32(0x10_FE_11_12))
    packetBuilder.append(UInt32(0x10_FF_13_14))

    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
    XCTAssertEqual(10, receiver.received.count)
    XCTAssertEqual(receiver.received[0], "timeCodeQuarterFrame 1")
    XCTAssertEqual(receiver.received[1], "songPositionPointer 515")
    XCTAssertEqual(receiver.received[2], "songSelect 5")
    XCTAssertEqual(receiver.received[3], "tuneRequest")
    XCTAssertEqual(receiver.received[4], "timingClock")
    XCTAssertEqual(receiver.received[5], "startCurrentSequence")
    XCTAssertEqual(receiver.received[6], "continueCurrentSequence")
    XCTAssertEqual(receiver.received[7], "stopCurrentSequence")
    XCTAssertEqual(receiver.received[8], "activeSensing")
    XCTAssertEqual(receiver.received[9], "reset")
  }

  func testParsingMIDI2ChannelVoiceMessages() {
    packetBuilder.append(UInt32(0x41_81_01_02), UInt32(0x12_34_56_78))
    packetBuilder.append(UInt32(0x41_92_03_04), UInt32(0x23_45_67_89))
    packetBuilder.append(UInt32(0x41_A3_04_FF), UInt32(0xFF_FF_FF_FF))
    packetBuilder.append(UInt32(0x41_B4_05_08), UInt32(0x12_34_56_78))
    packetBuilder.append(UInt32(0x41_C5_09_FF), UInt32(0xFF_FF_FF_FF))
    packetBuilder.append(UInt32(0x41_C5_01_00), UInt32(0xFF_FF_FF_FF))
    packetBuilder.append(UInt32(0x41_D6_0B_0C), UInt32(0x12_34_56_78))
    packetBuilder.append(UInt32(0x41_E7_0D_0E), UInt32(0x00_00_00_07))

    packetBuilder.append(UInt32(0x41_08_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_18_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_28_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_38_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_48_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_58_0D_0E), UInt32(0xFF_12_34_07))

    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
    XCTAssertEqual(14, receiver.received.count)
    XCTAssertEqual(receiver.received[0], "noteOff2 1 4660 2 22136")
    XCTAssertEqual(receiver.received[1], "noteOn2 3 9029 4 26505")
    XCTAssertEqual(receiver.received[2], "polyphonicKeyPressure2 4 4294967295")
    XCTAssertEqual(receiver.received[3], "controlChange2 5 305419896")
    XCTAssertEqual(receiver.received[4], "programChange2 255 65535")
    XCTAssertEqual(receiver.received[5], "programChange 255")
    XCTAssertEqual(receiver.received[6], "channelPressure2 305419896")
    XCTAssertEqual(receiver.received[7], "pitchBendChange2 7")

    XCTAssertEqual(receiver.received[8], "registeredPerNoteControllerChange 13 14 7")
    XCTAssertEqual(receiver.received[9], "assignablePerNoteControllerChange 13 14 7")
    XCTAssertEqual(receiver.received[10], "registeredControllerChange 3342 7")
    XCTAssertEqual(receiver.received[11], "assignableControllerChange 3342 7")
    XCTAssertEqual(receiver.received[12], "relativeRegisteredControllerChange 3342 7")
    XCTAssertEqual(receiver.received[13], "relativeAssignableControllerChange 3342 -15584249")
  }

  func testPerNoteManagement() {
    packetBuilder.append(UInt32(0x41_F0_11_32), UInt32(0x56_78_9A_BC))
    packetBuilder.append(UInt32(0x41_F0_12_33), UInt32(0x56_78_9A_BC))
    packetBuilder.append(UInt32(0x41_F0_13_34), UInt32(0x56_78_9A_BC))
    packetBuilder.append(UInt32(0x41_F0_14_35), UInt32(0x56_78_9A_BC))
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
    XCTAssertEqual(receiver.received[0], "perNoteManagement 17 true false")
    XCTAssertEqual(receiver.received[1], "perNoteManagement 18 true true")
    XCTAssertEqual(receiver.received[2], "perNoteManagement 19 false false")
    XCTAssertEqual(receiver.received[3], "perNoteManagement 20 false true")
  }

  func testParserWithoutReceiver() {
    midi.receiver = nil
    packetBuilder.append(UInt32(0x41_F0_11_32), UInt32(0x56_78_9A_BC))
    packetBuilder.append(UInt32(0x41_F0_12_33), UInt32(0x56_78_9A_BC))
    packetBuilder.append(UInt32(0x41_F0_13_34), UInt32(0x56_78_9A_BC))
    packetBuilder.append(UInt32(0x41_F0_14_35), UInt32(0x56_78_9A_BC))
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserIgnoresUnknownUniversalMessageType() {
    packetBuilder.append(UInt32(0xF1_F0_11_32), UInt32(0x56_78_9A_BC))
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
    XCTAssertTrue(receiver.received.isEmpty)
  }

  class DummyReceiver: MorkAndMIDI.Receiver {}

  func testReceiverProtocolDefaultStubs() {
    let dummy = DummyReceiver()
    midi.receiver = dummy
    // MIDI 1 channel voice msgs
    packetBuilder.append(UInt32(0x21_81_01_02))
    packetBuilder.append(UInt32(0x21_92_03_04))
    packetBuilder.append(UInt32(0x21_A3_05_06))
    packetBuilder.append(UInt32(0x21_B4_07_08))
    packetBuilder.append(UInt32(0x21_C5_09_0A))
    packetBuilder.append(UInt32(0x21_D6_0B_0C))
    packetBuilder.append(UInt32(0x21_E7_0D_0E))

    // MIDI 1 system msgs
    packetBuilder.append(UInt32(0x10_F1_01_02))
    packetBuilder.append(UInt32(0x10_F2_03_04))
    packetBuilder.append(UInt32(0x10_F3_05_06))
    packetBuilder.append(UInt32(0x10_F6_07_08))
    packetBuilder.append(UInt32(0x10_F8_09_0A))
    packetBuilder.append(UInt32(0x10_FA_0B_0C))
    packetBuilder.append(UInt32(0x10_FB_0D_0E))
    packetBuilder.append(UInt32(0x10_FC_0F_10))
    packetBuilder.append(UInt32(0x10_FE_11_12))
    packetBuilder.append(UInt32(0x10_FF_13_14))

    // MIDI 2 channel voice msgs
    packetBuilder.append(UInt32(0x41_81_01_02), UInt32(0x12_34_56_78))
    packetBuilder.append(UInt32(0x41_92_03_04), UInt32(0x23_45_67_89))
    packetBuilder.append(UInt32(0x41_A3_04_FF), UInt32(0xFF_FF_FF_FF))
    packetBuilder.append(UInt32(0x41_B4_05_08), UInt32(0x12_34_56_78))
    packetBuilder.append(UInt32(0x41_C5_09_FF), UInt32(0xFF_FF_FF_FF))
    packetBuilder.append(UInt32(0x41_C5_01_00), UInt32(0xFF_FF_FF_FF))
    packetBuilder.append(UInt32(0x41_D6_0B_0C), UInt32(0x12_34_56_78))
    packetBuilder.append(UInt32(0x41_E7_0D_0E), UInt32(0x00_00_00_07))

    packetBuilder.append(UInt32(0x41_08_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_18_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_28_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_38_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_48_0D_0E), UInt32(0x00_00_00_07))
    packetBuilder.append(UInt32(0x41_58_0D_0E), UInt32(0xFF_12_34_07))
    packetBuilder.append(UInt32(0x41_68_0D_0E), UInt32(0xFF_12_34_07))

    // MIDI 2 per-note management
    packetBuilder.append(UInt32(0x41_F0_11_32), UInt32(0x56_78_9A_BC))
    packetBuilder.append(UInt32(0x41_F0_12_33), UInt32(0x56_78_9A_BC))
    packetBuilder.append(UInt32(0x41_F0_13_34), UInt32(0x56_78_9A_BC))
    packetBuilder.append(UInt32(0x41_F0_14_35), UInt32(0x56_78_9A_BC))
    
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: 456, words: pointer.words())
    }
  }
}
