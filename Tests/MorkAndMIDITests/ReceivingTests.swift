// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class ReceivingTests: MIDITestCase {

  override func setUp() {
    super.setUp()
    receiver = .init()
    midi.receiver = receiver
  }

  override func tearDown() {
    super.tearDown()
  }

  func sendMIDIPackets(source: MIDIEndpointRef) {
    let packetBuilder = MIDIPacketList.Builder(byteSize: MemoryLayout<MIDIPacketList>.size / MemoryLayout<UInt8>.stride)

    let payloads = [
      // v1 note ON
      [UInt8(0x91), UInt8(0x60), UInt8(0x7F)],
      // v1 note OFF
      [UInt8(0x81), UInt8(0x60), UInt8(0x00)]
    ]

    for bytes in payloads {
      packetBuilder.append(timestamp: mach_absolute_time(), data: bytes)
    }

    XCTAssertTrue(midi.channels.isEmpty)
    _ = packetBuilder.withUnsafePointer {
      MIDIReceived(source1, $0)
    }
  }

  func sendMIDIEvents(source: MIDIEndpointRef, protocol: MIDIProtocolID) {
    let packetBuilder = MIDIEventList.Builder(inProtocol: `protocol`,
                                              wordSize: MemoryLayout<MIDIEventList>.size / MemoryLayout<UInt32>.stride)
    let payloads = [
      // v1 note ON/OFF
      [UInt32(0x21_91_60_7F)], [UInt32(0x21_81_60_00)],
      // v2 note ON/OFF
      [UInt32(0x41_92_03_04), UInt32(0x23_45_67_89), UInt32(0x41_81_01_02), UInt32(0x12_34_56_78)]
    ]

    for words in payloads {
      packetBuilder.append(timestamp: mach_absolute_time(), words: words)
    }

    XCTAssertTrue(midi.channels.isEmpty)
    _ = packetBuilder.withUnsafePointer {
      MIDIReceivedEventList(source1, $0)
    }
  }

  func testMIDIv2ReceivingMIDIv2() {
    createSource1()
    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(source1.uniqueId) }
    sendMIDIEvents(source: source1, protocol: ._2_0)
    checkUntil(elapsed: 5.0) { midi.channels[source1.uniqueId] != nil }
    XCTAssertEqual(receiver.received, [
      "noteOn 96 127",
      "noteOff 96 0",
      "noteOn2 3 9029 4 26505",
      "noteOff2 1 4660 2 22136"
    ])
  }

  func testMIDIv2ReceivingMIDIv1() {
    createSource1()
    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(source1.uniqueId) }
    sendMIDIEvents(source: source1, protocol: ._1_0)
    checkUntil(elapsed: 5.0) { midi.channels[source1.uniqueId] != nil }
    XCTAssertEqual(receiver.received, [
      "noteOn2 96 65535 0 0",
      "noteOff2 96 0 0 0",
      "noteOn2 3 9029 4 26505",
      "noteOff2 1 4660 2 22136"
    ])
  }

  func testMIDIv2ReceivingLegacyMIDIv1() {
    createSource1()
    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(source1.uniqueId) }
    sendMIDIPackets(source: source1)
    checkUntil(elapsed: 5.0) { midi.channels[source1.uniqueId] != nil }
    XCTAssertEqual(receiver.received, [
      "noteOn2 96 65535 0 0",
      "noteOff2 96 0 0 0"
    ])
  }

  func testMIDIv1ReceivingMIDIv2() {
    createMIDIWithoutStarting(midiProtocol: ._1_0)
    midi.start()
    createSource1()
    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(source1.uniqueId) }
    sendMIDIEvents(source: source1, protocol: ._2_0)
    checkUntil(elapsed: 5.0) { midi.channels[source1.uniqueId] != nil }

    // FIXME - this does not look correct
    XCTAssertEqual(receiver.received, [
      "noteOn 3 17",
      "noteOff 1 9"
    ])
  }

  func testMIDIv1ReceivingMIDIv1() {
    createMIDIWithoutStarting(midiProtocol: ._1_0)
    midi.start()
    createSource1()
    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(source1.uniqueId) }
    sendMIDIEvents(source: source1, protocol: ._1_0)
    checkUntil(elapsed: 5.0) { midi.channels[source1.uniqueId] != nil }
    XCTAssertEqual(receiver.received, [
      "noteOn 96 127",
      "noteOff 96 0",
      "noteOn2 3 9029 4 26505",
      "noteOff2 1 4660 2 22136"
    ])
  }

  func testMIDIv1ReceivingLegacyMIDIv1() {
    createMIDIWithoutStarting(midiProtocol: ._1_0)
    midi.start()
    createSource1()
    checkUntil(elapsed: 5.0) { midi.activeConnections.contains(source1.uniqueId) }
    sendMIDIPackets(source: source1)
    checkUntil(elapsed: 5.0) { midi.channels[source1.uniqueId] != nil }
    XCTAssertEqual(receiver.received, [
      "noteOn 96 127",
      "noteOff 96 0"
    ])
  }
}
