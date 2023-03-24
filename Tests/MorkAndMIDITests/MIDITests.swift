// Copyright © 2021 Brad Howes. All rights reserved.

@testable import MorkAndMIDI
import CoreMIDI
import XCTest

#if os(macOS)
class MIDITests: XCTestCase {

  var midi: MIDI!
  var monitor: Monitor!

  override func setUp() {
    super.setUp()
    midi = MIDI(clientName: "foo", uniqueId: 12_345)
    monitor = Monitor(self)
    midi.monitor = monitor
  }

  override func tearDown() {
    midi?.stop()
    midi = nil
    monitor = nil
    super.tearDown()
  }

  func setMonitorExpectation(_ kind: Monitor.ExpectationKind) {
    monitor.setExpectation(kind)
    midi.start()
    waitForExpectations(timeout: 15.0)
  }

  func testDeinitialized() {
    monitor.setExpectation(.deinitialized)
    midi.start()
    midi.stop()
    midi = nil
    waitForExpectations(timeout: 15.0)
  }

  func testStartup() {
    setMonitorExpectation(.initialized)
  }

  func testMIDIObjectReDisplayName() {
    let ref: MIDIObjectRef = 0
    let name = ref.displayName
    XCTAssertEqual(name, "nil")
  }

  func testEndToEnd() {
    let receiver = Receiver(self)
    receiver.channel = -1
    midi.receiver = receiver
    receiver.setExpectation(.noteOff)
    midi.start()

    var source: MIDIEndpointRef = .init()
    let ourUniqueId: MIDIUniqueID = 1234567
    var client: MIDIClientRef = .init()
    var err = MIDIClientCreateWithBlock("TestClient" as CFString, &client, nil)
    XCTAssertEqual(err, 0)

    err = MIDISourceCreateWithProtocol(client, "TestSender" as CFString, ._2_0, &source)
    XCTAssertEqual(err, 0)

    MIDIObjectSetIntegerProperty(source, kMIDIPropertyUniqueID, ourUniqueId)
    MIDIObjectSetIntegerProperty(source, kMIDIPropertyTransmitsNotes, 1)
    MIDIObjectSetIntegerProperty(source, kMIDIPropertyMaxTransmitChannels, 16)

    let packetBuilder = MIDIEventList.Builder(inProtocol: ._1_0,
                                              wordSize: MemoryLayout<MIDIEventList>.size / MemoryLayout<UInt32>.stride)
    packetBuilder.append(timestamp: 0, words: [UInt32(0x21_81_01_02)])
    _ = packetBuilder.withUnsafePointer { MIDIReceivedEventList(source, $0) }

    waitForExpectations(timeout: 15.0)
  }

  func flaky_testUpdatedDevices() {
    setMonitorExpectation(.updatedDevices)
    // XCTAssertEqual(midi.devices.count, 1)
  }

  func flaky_testUpdatedConnections() {
    setMonitorExpectation(.updatedConnections)
    // XCTAssertEqual(midi.activeConnections.count, 1)
  }
}
#endif
