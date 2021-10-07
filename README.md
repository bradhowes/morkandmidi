# SimplyMIDI

A really basic wrapper for [CoreMIDI](https://developer.apple.com/documentation/coremidi)
that opens a virtual destination and connects to any MIDI endpoints that appear on the network.

Currently just supports some MIDI v1 messages. However, it also provides enhancements to 
`MIDIPacket` and `MIDIPacketList` to support building new ones and to parse them.
