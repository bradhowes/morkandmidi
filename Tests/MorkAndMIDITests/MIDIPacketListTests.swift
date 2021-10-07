// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MIDIPacketListTests: XCTestCase {

  func testListBuilder() {
    let a = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet
    let b = MIDIPacket.Builder(timestamp: 1, data: [0x91, 65, 33, 0x81, 65, 10, 0x81, 66, 0]).packet

    var builder = MIDIPacketList.Builder()
    builder.add(packet: a)
    builder.add(packet: b)

    let list = builder.packetList
    XCTAssertEqual(list.numPackets, 2)

    for (index, packet) in list.enumerated() {
      switch index {
      case 0:
        XCTAssertEqual(packet.timeStamp, 0)
        XCTAssertEqual(packet.length, 6)
        XCTAssertEqual(packet.data.0, 0x91)
        XCTAssertEqual(packet.data.1, 64)
        XCTAssertEqual(packet.data.2, 32)
        XCTAssertEqual(packet.data.3, 0x81)
        XCTAssertEqual(packet.data.4, 64)
        XCTAssertEqual(packet.data.5, 0)

      case 1:
        XCTAssertEqual(packet.timeStamp, 1)
        XCTAssertEqual(packet.length, 9)
        XCTAssertEqual(packet.data.0, 0x91)
        XCTAssertEqual(packet.data.1, 65)
        XCTAssertEqual(packet.data.2, 33)
        XCTAssertEqual(packet.data.3, 0x81)
        XCTAssertEqual(packet.data.4, 65)
        XCTAssertEqual(packet.data.5, 10)
        XCTAssertEqual(packet.data.6, 0x81)
        XCTAssertEqual(packet.data.7, 66)
        XCTAssertEqual(packet.data.8, 0)
      default: fatalError()
      }
    }
  }

  func testListsParsing() {
    let receiver = Receiver()

    var builder = MIDIPacketList.Builder()
    builder.add(packet: MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet)
    builder.add(packet: MIDIPacket.Builder(timestamp: 1, data: [0x91, 65, 33, 0x81, 65, 10, 0x81, 66, 0]).packet)

    let list = builder.packetList
    XCTAssertEqual(list.numPackets, 2)
    list.parse(receiver: receiver, monitor: nil, uniqueId: 0)

    XCTAssertEqual(receiver.received, [
      Receiver.Event(cmd: 0x90, data1: 64, data2: 32),
      Receiver.Event(cmd: 0x80, data1: 64, data2: 0),
      Receiver.Event(cmd: 0x90, data1: 65, data2: 33),
      Receiver.Event(cmd: 0x80, data1: 65, data2: 10),
      Receiver.Event(cmd: 0x80, data1: 66, data2: 0)
    ])
  }

  func testMonitoringTraffic() {
    let monitor = Monitor(self)

    var builder = MIDIPacketList.Builder()
    builder.add(packet: MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet)
    builder.add(packet: MIDIPacket.Builder(timestamp: 1, data: [0x91, 65, 33, 0x81, 65, 10, 0x82, 66, 0]).packet)

    let list = builder.packetList
    XCTAssertEqual(list.numPackets, 2)

    let uniqueId: MIDIUniqueID = 123
    list.parse(receiver: nil, monitor: monitor, uniqueId: uniqueId)

    XCTAssertEqual(monitor.uniqueIds[uniqueId], 2)
  }
}
