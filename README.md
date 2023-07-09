[![Swift](https://github.com/bradhowes/morkandmidi/workflows/CI/badge.svg)]()
[![COV](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bradhowes/1190477db6ce37d6f5d8e8be5ac6b752/raw/MorkAndMIDI-coverage.json)](https://github.com/bradhowes/morkandmidi/blob/main/.github/workflows/CI.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2Fmorkandmidi%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/bradhowes/morkandmidi)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2Fmorkandmidi%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/bradhowes/morkandmidi)
[![License: MIT](https://img.shields.io/badge/License-MIT-A31F34.svg)](https://opensource.org/licenses/MIT)


# MorkAndMIDI

A really thin Swift layer on top of [Core MIDI](https://developer.apple.com/documentation/coremidi)
that opens a virtual MIDI destination and port and connects to any MIDI endpoints that appear on the network,
no questions asked.

Currently just supports some MIDI v1 messages. However, it also provides enhancements to
`MIDIPacket` and `MIDIPacketList` to support building new ones and to parse them.

# Features

This package basically sets up MIDI and connects to all available inputs it finds. Connection state can be monitored by
installing a `Monitor` instance, and actual MIDI commands can be observed by installing a `Receiver` instance.
Everything else should be handled automatically by the package.

# To Use

Create a new MIDI instance passing in a name to use for the endpoints that it will create, and a unique ID that will be
assigned to the endpoints:

```swift
let midi = MIDI(clientName: "Na-Nu Na-Nu", uniqueId: 12_345)
midi.monitor = my_monitor
midi.receiver = my_receiver
midi.start()
```

Ideally, this `uniqueId` value will actually be unique to your MIDI network. However, there is no way to
guarantee that so instead one should install a `Monitor` to observe the unique ID value that is passed to
`Monitor.initialized` routine once initialization is complete. When there are no conflicts, this value
will be the same as the one given in the `MIDI` constructor. If there was a conflict, you should be
given a value provided by the system.

# CoreMIDI Protocol Version

The package supports the following CoreMIDI MIDIProtocolID values along with a legacy mode:

* MIDIProto.legacy -- use the older MIDIPacket format (MIDI v1 message format)
* MIDIProto.v1_0 -- use the newer MIDIEventPacket format with MIDI v1 messages (CoreMIDI MIDIProtocolID._1_0)
* MIDIProto.v2_0 -- use the newer MIDIEventPacket format with MIDI v2 messages (CoreMIDI MIDIProtocolID._2_0)

The _legacy_ mode is probably the safest for now as it has had the most testing in my SoundFonts app.

# Processing MIDI Messages

The `Receiver` protocol defines functions that will be called for MIDI commands that arrive over USB or the network.
Since they are all optional, you only need to implement the commands you want.

Note that at the moment, SysExc (0xF0) commands are not supported and are silently ignored. I have no need for them,
but supporting them should not be too difficult a task -- you just need to buffer MIDI packets until it is complete.

# Connectivity

The `MIDI` class listens for changes to the MIDI nework and creates / destroys connections to external devices when necessary.
The `Monitor` protocol has methods you can implement to be notified when connections and/or devices change. There is also a
way to track the MIDI channel being used by an external device.


[License Badge]: https://img.shields.io/github/license/bradhowes/AStar.svg?color=yellow "MIT License"
[License]: https://github.com/bradhowes/AStar/blob/master/LICENSE.txt

[Swift Badge]: https://img.shields.io/badge/swift-5.3-orange.svg "Swift 5.3"
[Swift]: https://swift.org/blog/swift-5-3-released/
