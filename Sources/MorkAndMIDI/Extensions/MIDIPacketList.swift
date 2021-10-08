// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import os

/// Allow iterating over the packets in a MIDIPacketList
extension MIDIPacketList: Sequence {

  private var log: OSLog { Logging.logger("MIDIPacketList") }

  public typealias Element = MIDIPacket

  public var count: UInt32 { self.numPackets }

  public func makeIterator() -> AnyIterator<Element> {
    var current: MIDIPacket = packet
    var index: UInt32 = 0
    return AnyIterator {
      guard index < self.numPackets else { return nil }
      defer {
        current = MIDIPacketNext(&current).pointee
        index += 1
      }
      return current
    }
  }
}

extension MIDIPacketList {

  /**
   Extract MIDI messages from the packets and process them

   - parameter receiver: optional entity to process MIDI messages
   - parameter monitor: optional entity to monitor MIDI traffic
   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the messages
   */
  public func parse(midi: MIDI, uniqueId: MIDIUniqueID) {
    os_signpost(.begin, log: log, name: "parse")
    os_log(.info, log: log, "processPackets - %d", numPackets)
    for packet in self {
      os_signpost(.begin, log: log, name: "sendToController")
      packet.parse(midi: midi, uniqueId: uniqueId)
      os_signpost(.end, log: log, name: "sendToController")
    }
    os_signpost(.end, log: log, name: "parse")
  }
}

extension MIDIPacketList {

  /**
   Builder of MIDIPacketList instances from a collection of MIDIPacket entities
   */
  public struct Builder {

    private var packets = [MIDIPacket]()

    /**
     Add a MIDIPacket to the collection

     - parameter packet: the MIDIPacket to add
     */
    public mutating func add(packet: MIDIPacket) { packets.append(packet) }

    /// Obtain a MIDIPacketList from the MIDIPacket collection
    public var packetList: MIDIPacketList {

      let packetsSize = (packets.map { $0.alignedByteSize }).reduce(0, +)
      let listSize = MemoryLayout<MIDIPacketList>.size - MemoryLayout<MIDIPacket>.size + packetsSize

      func optionalMIDIPacketListAdd(_ packetListPtr: UnsafeMutablePointer<MIDIPacketList>,
                                     _ curPacketPtr: UnsafeMutablePointer<MIDIPacket>,
                                     _ packet: MIDIPacket) -> UnsafeMutablePointer<MIDIPacket>? {
        return withUnsafeBytes(of: packet.data) { ptr in
          return MIDIPacketListAdd(packetListPtr, listSize, curPacketPtr, packet.timeStamp,
                                   Int(packet.length), ptr.bindMemory(to: UInt8.self).baseAddress!)
        }
      }

      // Build the MIDIPacketList in the memory allocated by Data and then take it over
      var buffer = Data(count: listSize)
      return buffer.withUnsafeMutableBytes { (bufferPtr: UnsafeMutableRawBufferPointer) -> MIDIPacketList in
        let packetListPtr = bufferPtr.bindMemory(to: MIDIPacketList.self).baseAddress!
        var curPacketPtr = MIDIPacketListInit(packetListPtr)
        for packet in packets {
          guard let newPacketPtr = optionalMIDIPacketListAdd(packetListPtr, curPacketPtr, packet) else {
            fatalError()
          }
          curPacketPtr = newPacketPtr
        }
        return packetListPtr.move()
      }
    }
  }
}
