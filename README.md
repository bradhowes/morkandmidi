# MorkAndMIDI

A really basic wrapper for [CoreMIDI](https://developer.apple.com/documentation/coremidi)
that opens a virtual destination and connects to any MIDI endpoints that appear on the network.

Currently just supports some MIDI v1 messages. However, it also provides enhancements to
`MIDIPacket` and `MIDIPacketList` to support building new ones and to parse them.

# Features

This package basically sets up MIDI and connects to all available inputs it finds. Connection state can be monitored by
installing a `Monitor` instance, and actual MIDI commands can be observed by installing a `Receiver` instance.
Everything else should be handle automatically by the package.

# To Use

Create a new MIDI instance passing in a name to use for the endpoints that it will create, and a unique ID that will be
assigned to the endpoints. Ideally, this value will be unique to your application. However, there is no way to
guarantee that so instead one should install a `Monitor` to observe the unique ID value that is given once
initialization is complete. When there are no conflicts, this value will be the same as the one given in the `MIDI`
constructor. If there was a conflict, you should be given a value provided by the system.
