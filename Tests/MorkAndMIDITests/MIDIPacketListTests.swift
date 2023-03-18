// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

class MIDIPacketListTests: XCTestCase {

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

  func testMonitoringTraffic() {
    let monitor = Monitor(self)
    midi.monitor = monitor

//    let builder = MIDIPacketList.Builder(byteSize: 0)
//    builder.append(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0])
//    builder.append(timestamp: 1, data: [0x91, 65, 33, 0x81, 65, 10, 0x82, 66, 0])
//
//    builder.withUnsafePointer { pointer in
//      XCTAssertEqual(2, pointer.pointee.count)
//    }

    // let uniqueId: MIDIUniqueID = 123
    // list.parse(midi: midi, uniqueId: uniqueId)
    // XCTAssertEqual(monitor.uniqueIds[uniqueId], 2)
  }
}
