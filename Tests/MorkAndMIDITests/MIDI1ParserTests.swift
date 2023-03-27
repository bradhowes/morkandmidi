// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MIDI1ParserTests: XCTestCase {

  var midi: MIDI!
  var parser: MIDI1Parser!
  var receiver: Receiver!
  var packetBuilder: MIDIPacket.Builder!
  let sourceUniqueId: MIDIUniqueID = 10101

  override func setUp() {
    super.setUp()
    midi = MIDI(clientName: "Na-nu Na-nu", uniqueId: 12_345, midiProtocol: ._1_0)
    parser = MIDI1Parser()
    receiver = Receiver(self)
    midi.receiver = receiver
    packetBuilder = .init(maximumNumberMIDIBytes: 64)
    packetBuilder.timeStamp = 0
  }

  override func tearDown() {
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

      default:
        packetBuilder.append(bytes[index], bytes[index + 1], bytes[index + 2])
        index += 3
      }
    }
    packetBuilder.withUnsafePointer { pointer in
      parser.parse(midi: midi, uniqueId: sourceUniqueId, bytes: pointer.bytes())
    }
  }

  func testParser() {
    sendMessage(bytes: [0x91, 64, 32], channel: -1)
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
                    "reset"])
  }
}
