// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI
import os

public extension MIDIPacket {

  /// MIDI commands (v1)
  enum MsgKind: UInt8 {
    case noteOff = 0x80
    case noteOn = 0x90
    case polyphonicKeyPressure = 0xA0
    case controlChange = 0xB0
    case programChange = 0xC0
    case channelPressure = 0xD0
    case pitchBendChange = 0xE0
    case systemExclusive = 0xF0
    case timeCodeQuarterFrame = 0xF1
    case songPositionPointer = 0xF2
    case songSelect = 0xF3
    case tuneRequest = 0xF6
    case timingClock = 0xF8
    case startCurrentSequence = 0xFA
    case continueCurrentSequence = 0xFB
    case stopCurrentSequence = 0xFC
    case activeSensing = 0xFE
    case reset = 0xFF

    /**
     Attempt to convert a byte into a MIDI command.

     - parameter raw: the byte to use
     */
    init?(_ raw: UInt8) {
      // Commands starting at 0xF0 require the whole byte, not just the upper 4 bits.
      let highNibble = raw & 0xF0
      self.init(rawValue: highNibble == 0xF0 ? raw : highNibble)
    }

    /// True if MIDI message has channel
    var hasChannel: Bool { self.rawValue < 0xF0 }

    /// Number of additional bytes needed by a MIDI command. For systemExclusive, set to very large value in order to
    /// stop parsing of the MIDIPacket since we don't support systemExclusive messages.
    var byteCount: Int {
      switch self {
      case .noteOff: return 2
      case .noteOn: return 2
      case .polyphonicKeyPressure: return 2
      case .controlChange: return 2
      case .programChange: return 1
      case .channelPressure: return 1
      case .pitchBendChange: return 2
      case .systemExclusive: return 65_537 // !!!
      case .timeCodeQuarterFrame: return 1
      case .songPositionPointer: return 2
      case .songSelect: return 1
      case .tuneRequest: return 0
      case .timingClock: return 0
      case .startCurrentSequence: return 0
      case .continueCurrentSequence: return 0
      case .stopCurrentSequence: return 0
      case .activeSensing: return 0
      case .reset: return 0
      }
    }
  }
}

public extension MIDIPacket {

  private var log: OSLog { Logging.logger("MIDIPacket") }

  /**
   Builder of MIDIPacket instances from a collection of UInt8 values
   */
  struct Builder {

    /// The timestamp for all of the MIDI events recorded in the data
    public let timestamp: MIDITimeStamp

    private var data = [UInt8]()

    /**
     Create a new builder

     - parameter timestamp: the timestamp for all of the events in the packet
     - parameter data: the initial data to record
     */
    public init(timestamp: MIDITimeStamp, data: [UInt8] = []) {
      self.timestamp = timestamp
      self.data = data
    }

    /**
     Create a new builder

     - parameter timestamp: the timestamp for all of the events in the packet
     - parameter msg: the MIDI command to add
     */
    public init(timestamp: MIDITimeStamp, msg: MsgKind) {
      self.timestamp = timestamp
      self.data = [msg.rawValue]
    }

    /**
     Create a new builder

     - parameter timestamp: the timestamp for all of the events in the packet
     - parameter msg: the MIDI command to add
     - parameter data1: the first data value
     */
    public init(timestamp: MIDITimeStamp, msg: MsgKind, data1: UInt8) {
      self.timestamp = timestamp
      self.data = [msg.rawValue, data1]
    }

    /**
     Create a new builder

     - parameter timestamp: the timestamp for all of the events in the packet
     - parameter msg: the MIDI command to add
     - parameter data1: the first data value
     - parameter data2: the second data value
     */
    public init(timestamp: MIDITimeStamp, msg: MsgKind, data1: UInt8, data2: UInt8) {
      self.timestamp = timestamp
      self.data = [msg.rawValue, data1, data2]
    }

    /**
     Add additional MID commands to the current collection

     - parameter data: MIDI data to add to the packet
     */
    public mutating func add(data: [UInt8]) {
      self.data.append(contentsOf: data)
    }

    /**
     Add additional MID commands to the current collection

     - parameter data: MIDI data to add to the packet
     */
    public mutating func add(msgKind: MsgKind) {
      self.data.append(msgKind.rawValue)
    }

    /**
     Add additional MID commands to the current collection

     - parameter data: MIDI data to add to the packet
     */
    public mutating func add(msgKind: MsgKind, data1: UInt8) {
      self.data.append(contentsOf: [msgKind.rawValue, data1])
    }

    /**
     Add additional MID commands to the current collection

     - parameter data: MIDI data to add to the packet
     */
    public mutating func add(msgKind: MsgKind, data1: UInt8, data2: UInt8) {
      self.data.append(contentsOf: [msgKind.rawValue, data1, data2])
    }

    /// Obtain a MIDIPacket from the MIDI data collection.
    public var packet: MIDIPacket {
      var packet = MIDIPacket()
      precondition(data.count <= 256)
      packet.timeStamp = timestamp
      packet.length = UInt16(data.count)
      withUnsafeMutableBytes(of: &packet.data) { $0.copyBytes(from: data) }
      return packet
    }
  }
}

public extension MIDIPacket {

  /// MIDIPacket instances must be aligned on 4-byte boundaries. Obtain the packet size + any padding to stay aligned
  var alignedByteSize: Int {
    ((MemoryLayout<MIDITimeStamp>.size + MemoryLayout<UInt16>.size + Int(self.length) + 3) / 4) * 4
  }

  /**
   Extract MIDI messages from the packets and process them

   - parameter midi: controller of MIDI processing
   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the messages
   */
  func parse(midi: MIDI, uniqueId: MIDIUniqueID) {
    let byteCount = Int(self.length)

    // Uff. In testing with Arturia Minilab mk II, I can sometimes generate packets with zero or really big
    // sizes of 26624 (0x6800!)
    if byteCount == 0 || byteCount > 64 {
      os_log(.error, log: log, "suspect packet size %d", byteCount)
      return
    }

    os_log(.debug, log: log, "packet - %ld %d bytes", timeStamp, byteCount)

    // Visit the individual bytes until all consumed. If there is something we don't understand, we stop processing the
    // packet.
    withUnsafeBytes(of: self.data) { ptr in
      var index: Int = 0
      let receiverChannel = midi.receiver?.channel ?? -2
      while index < byteCount {
        let status = ptr[index]
        index += 1

        // We have no way to know how to skip over an unknown command, so just drop rest of packet
        guard let command = MsgKind(status) else { break }
        let needed = command.byteCount

        // We have enough information to update the channel that an endpoint is sending on
        if command.hasChannel {
          let packetChannel = Int(status & 0x0F)
          os_log(.debug, log: log, "message: %d packetChannel: %d needed: %d", command.rawValue, packetChannel, needed)
          midi.updateEndpointChannel(uniqueId: uniqueId, channel: packetChannel)
          midi.monitor?.seen(uniqueId: uniqueId, channel: packetChannel)

          // Filter out messages if they come on a channel we are not listening to
          guard receiverChannel == -1 || receiverChannel == packetChannel else {
            index += needed
            continue
          }
        }

        // Not enough bytes to continue on
        guard index + needed <= byteCount else { break }

        if let receiver = midi.receiver {
          switch command {
          case .noteOff: receiver.noteOff(note: ptr[index], velocity: ptr[index + 1])
          case .noteOn: receiver.noteOn(note: ptr[index], velocity: ptr[index + 1])
          case .polyphonicKeyPressure: receiver.polyphonicKeyPressure(note: ptr[index], pressure: ptr[index + 1])
          case .controlChange: receiver.controlChange(controller: ptr[index], value: ptr[index + 1])
          case .programChange: receiver.programChange(program: ptr[index])
          case .channelPressure: receiver.channelPressure(pressure: ptr[index])
          case .pitchBendChange: receiver.pitchBendChange(value: UInt16(ptr[index + 1]) << 7 + UInt16(ptr[index]))
          case .systemExclusive: break
          case .timeCodeQuarterFrame: break
          case .songPositionPointer: break
          case .songSelect: break
          case .tuneRequest: break
          case .timingClock: break
          case .startCurrentSequence: break
          case .continueCurrentSequence: break
          case .stopCurrentSequence: break
          case .activeSensing: break
          case .reset: receiver.allNotesOff()
          }
        }

        index += needed
      }
    }
  }
}
