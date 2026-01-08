// Copyright © 2023-2026 Brad Howes. All rights reserved.

import CoreMIDI
import MorkAndMIDI


let foo: Int32 = -1
let bar: UInt32 = UInt32(bitPattern: foo)

func boxUniqueId(_ uniqueId: MIDIUniqueID) -> UnsafeMutablePointer<MIDIUniqueID> {
  let refCon = UnsafeMutablePointer<MIDIUniqueID>.allocate(capacity: 1)
  refCon.initialize(to: uniqueId)
  return refCon
}

func unboxRefCon(_ refCon: UnsafeRawPointer?) -> MIDIUniqueID {
  guard let uniqueId = refCon?.assumingMemoryBound(to: MIDIUniqueID.self).pointee else { fatalError() }
  return uniqueId
}

let midi = MorkAndMIDI.MIDI(clientName: "Testing", uniqueId: 12345)

class Monitor: MorkAndMIDI.MonitorWithDefaults {
  func didInitialize(uniqueId: MIDIUniqueID) { print("monitor initialized -", uniqueId) }

  func willUpdateConnections() {
    print("willUpdateConnections")
  }

  func didConnect(to endpoint: MIDIEndpointRef) {
    print("didConnectTo: \(endpoint.uniqueId)")
    DispatchQueue.global(qos: .userInitiated).async {
      sendNotes()
    }
  }

  func didSee(uniqueId: MIDIUniqueID, channel: Int) {
    print("didSee \(uniqueId) channel: \(channel)")
  }

  func didUpdateConnections(added: [MIDIEndpointRef], removed: [MIDIEndpointRef]) {
    print("didUpdateConnctions \(added.map(\.uniqueId)) \(removed.map(\.uniqueId))")
  }

  func traffic(endpoint: MIDIEndpointRef) {
    print("traffic")
  }
}

let monitor = Monitor()
midi.monitor = monitor
midi.start()

let clientName = "Client"
var client: MIDIClientRef = .init()
err = MIDIClientCreateWithBlock(clientName as CFString, &client) {
  let messageID = $0.pointee.messageID
  if messageID  == .msgSetupChanged {
    print("client \(messageID.tag)")
  }
}
client

var virtualOut: MIDIEndpointRef = .init()
let virtualOutName = "Virtual Out"
var err = MIDISourceCreateWithProtocol(client, virtualOutName as CFString, ._2_0, &virtualOut)
virtualOut
virtualOut.uniqueId = 998877

let inputPortName = "Input 1"
var inputPort = MIDIPortRef()
err = MIDIInputPortCreateWithProtocol(client, inputPortName as CFString, ._2_0, &inputPort) { eventList, refCon in
  let uniqueId = unboxRefCon(refCon)
  print("inputPort message from", uniqueId)
  eventList.unsafeSequence().forEach { eventPacket in
    for word in eventPacket.words() {
      print(word.byte0.hex, word.byte1.hex, word.byte2.hex, word.byte3.hex)
    }
  }
}
inputPort

var refCon = boxUniqueId(virtualOut.uniqueId)
err = MIDIPortConnectSource(inputPort, virtualOut, refCon)

func sendNotes() {
  let packetBuilder = MIDIEventList.Builder(inProtocol: ._2_0,
                                            wordSize: MemoryLayout<MIDIEventList>.size / MemoryLayout<UInt32>.stride)
  packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_91_60_7F)])
  packetBuilder.append(timestamp: mach_absolute_time(), words: [UInt32(0x21_81_60_00)])
  err = packetBuilder.withUnsafePointer { MIDIReceivedEventList(virtualOut, $0) }
}

sendNotes()
