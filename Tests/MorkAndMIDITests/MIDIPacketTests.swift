// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MIDIPacketTests: XCTestCase {

  var midi: MIDI!

  override func setUp() {
    super.setUp()
    midi = MIDI(clientName: "Na-nu Na-nu", uniqueId: 12_345)
    midi.start()
  }

  override func tearDown() {
    midi.stop()
    midi = nil
    super.tearDown()
  }

  func testBuilder() {
    let builder = MIDIPacket.Builder(timestamp: 123, data: [1, 2, 3])
    let packet = builder.packet
    XCTAssertEqual(packet.length, 3)
    XCTAssertEqual(packet.timeStamp, 123)
    XCTAssertEqual(packet.data.0, 1)
    XCTAssertEqual(packet.data.1, 2)
    XCTAssertEqual(packet.data.2, 3)
  }

  func testAdd() {
    var builder = MIDIPacket.Builder(timestamp: 456, data: [1, 2, 3])
    builder.add(data: [4, 5, 6, 7])
    builder.add(data: [])
    builder.add(data: [8])

    let packet = builder.packet
    XCTAssertEqual(packet.length, 8)
    XCTAssertEqual(packet.timeStamp, 456)
    XCTAssertEqual(packet.data.0, 1)
    XCTAssertEqual(packet.data.1, 2)
    XCTAssertEqual(packet.data.2, 3)
    XCTAssertEqual(packet.data.3, 4)
    XCTAssertEqual(packet.data.4, 5)
    XCTAssertEqual(packet.data.5, 6)
    XCTAssertEqual(packet.data.6, 7)
    XCTAssertEqual(packet.data.7, 8)
  }

  func testParser() {
    let receiver = Receiver()
    midi.receiver = receiver
    receiver.channel = -1 // OMNI mode
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32]).packet
    noteOn.parse(midi: midi, uniqueId: 123)
    XCTAssertEqual(receiver.received, [Receiver.Event(cmd: 0x90, data1: 64, data2:32)])
  }

  func testParserFilteringOutOnChannelMismatch() {
    let receiver = Receiver()
    midi.receiver = receiver
    receiver.channel = 2
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32]).packet
    noteOn.parse(midi: midi, uniqueId: 123)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserReceivingOnChannelMatch() {
    let receiver = Receiver()
    midi.receiver = receiver
    receiver.channel = 1
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32]).packet
    noteOn.parse(midi: midi, uniqueId: 123)
    XCTAssertEqual(receiver.received, [Receiver.Event(cmd: 0x90, data1: 64, data2: 32)])
  }

  func testParserSkippingUnknownMessage() {
    let receiver = Receiver()
    midi.receiver = receiver
    let bogus = MIDIPacket.Builder(timestamp: 0, data: [0xF4, 0x91, 64, 32]).packet
    bogus.parse(midi: midi, uniqueId: 123)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserSkippingIncompleteMessage() {
    let receiver = Receiver()
    midi.receiver = receiver
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64]).packet
    noteOn.parse(midi: midi, uniqueId: 123)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserMultipleMessages() {
    let receiver = Receiver()
    midi.receiver = receiver
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet
    noteOn.parse(midi: midi, uniqueId: 123)
    XCTAssertEqual(receiver.received, [
      Receiver.Event(cmd: 0x90, data1: 64, data2: 32),
      Receiver.Event(cmd: 0x80, data1: 64, data2: 0)
    ])
  }

  func testAlignments() {
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: []).packet.alignedByteSize, 12)
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: [1]).packet.alignedByteSize, 12)
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: [1, 2]).packet.alignedByteSize, 12)
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: [1, 2, 3]).packet.alignedByteSize, 16)
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: [1, 2, 3, 4]).packet.alignedByteSize, 16)
  }
}
