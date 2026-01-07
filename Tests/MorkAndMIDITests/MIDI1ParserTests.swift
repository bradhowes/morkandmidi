// Copyright © 2021-2026 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MIDI1ParserTests: MIDITestCase {

  var parser: MIDI1Parser!
  var packetBuilder: MIDIPacket.Builder!
  let sourceUniqueId: MIDIUniqueID = 10101

  override func setUp() {
    super.setUp()
    parser = .init(midi: midi)
    packetBuilder = .init(maximumNumberMIDIBytes: 1024)
    packetBuilder.timeStamp = 0
  }

  override func tearDown() {
    midi.receiver = nil
    receiver = nil
    super.tearDown()
  }

  func sendMessage(bytes: [UInt8], channel: Int = -1) {
    receiver.channel = channel
    var index = 0;
    while index < bytes.count {
      switch (bytes.count - index) {
      case 1:
        packetBuilder.append(bytes[index])
        index += 1
      case 2:
        packetBuilder.append(bytes[index], bytes[index + 1])
        index += 2
      case 3:
        packetBuilder.append(bytes[index], bytes[index + 1], bytes[index + 2])
        index += 3
      default:
        packetBuilder.append(bytes[index], bytes[index + 1], bytes[index + 2], bytes[index + 3])
        index += 4
      }
    }
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(source: sourceUniqueId, bytes: pointer.bytes())
    }
  }

  func testParserCanParse() {
    sendMessage(bytes: [0x91, 64, 32])
    XCTAssertEqual(receiver.received, ["noteOn 64 32"])
  }

  func testParserFilteringOutOnChannelMismatch() {
    sendMessage(bytes: [0x91, 64, 32, 0x92, 63, 31], channel: 2)
    XCTAssertEqual(receiver.received, ["noteOn 63 31"])
  }

  func testParserReceivingOnChannelMatch() {
    sendMessage(bytes: [0x91, 64, 32], channel: 1)
    XCTAssertEqual(receiver.received, ["noteOn 64 32"])
  }

  func testParserSkippingUnknownMessage() {
    sendMessage(bytes: [0xF4, 0x91, 64, 32])
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserSkippingIncompleteMessage() {
    sendMessage(bytes: [0x91, 64])
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserMultipleMessages() {
    sendMessage(bytes: [0x91, 64, 32, 0x81, 64, 0])
    XCTAssertEqual(receiver.received, ["noteOn 64 32", "noteOff 64 0"])
  }

  func testParserIgnoresEmptyPackets() {
    sendMessage(bytes: [], channel: -1)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserIgnoresSysEx() {
    var zeros = Array<UInt8>.init(repeating: 0, count: 64)
    zeros[0] = 0xF0
    sendMessage(bytes: zeros, channel: -1)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserIgnoresMessagesAfterSysEx() {
    var zeros = Array<UInt8>.init(repeating: 0, count: 64 + 3)
    zeros[0] = 0xF0 // SYSEX
    zeros[64] = 0x91 // NOTE ON
    zeros[65] = 0x64
    zeros[66] = 0x32
    sendMessage(bytes: zeros, channel: -1)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserIgnoresNilReceiver() {
    midi.receiver = nil
    sendMessage(bytes: [0x91, 64, 32, 0x81, 64, 0])
  }

  class DummyReceiver: MorkAndMIDI.ReceiverWithDefaults {}

  func testDefaultReceiverStubs() {
    let receiver = DummyReceiver()
    midi.receiver = receiver
    sendMessage(bytes: [0x81, 64, 32,
                        0x91, 63, 0,
                        0xA1, 65, 123,
                        0xB1, 123, 45,
                        0xC1, 12,
                        0xD1, 23,
                        0xE1, 12, 34,
                        0xF1, 98,
                        0xF2, 76, 54,
                        0xF3, 32,
                        0xF6,
                        0xF8,
                        0xFA,
                        0xFB,
                        0xFC,
                        0xFE,
                        0xFF
                       ])
  }

  func testAllMessages() {
    sendMessage(bytes: [0x81, 64, 32,
                        0x91, 63, 0,
                        0xA1, 65, 123,
                        0xB1, 123, 45,
                        0xC1, 12,
                        0xD1, 23,
                        0xE1, 12, 34,
                        0xF1, 98,
                        0xF2, 76, 54,
                        0xF3, 32,
                        0xF6,
                        0xF8,
                        0xFA,
                        0xFB,
                        0xFC,
                        0xFE,
                        0xFF
                       ])
    XCTAssertEqual(receiver.received,
                   ["noteOff 64 32",
                    "noteOn 63 0",
                    "polyphonicKeyPressure 65 123",
                    "controlChange 123 45",
                    "programChange 12",
                    "channelPressure 23",
                    "pitchBendChange 4364",
                    "timeCodeQuarterFrame 98",
                    "songPositionPointer 6988",
                    "songSelect 32",
                    "tuneRequest",
                    "timingClock",
                    "startCurrentSequence",
                    "continueCurrentSequence",
                    "stopCurrentSequence",
                    "activeSensing",
                    "systemReset"])
  }
}
