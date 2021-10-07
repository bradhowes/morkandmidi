# MorkAndMIDI

A really thin Swift layer on top of [CoreMIDI](https://developer.apple.com/documentation/coremidi)
that opens a virtual MIDI destination and port and connects to any MIDI endpoints that appear on the network, 
no questions asked.

Currently just supports some MIDI v1 messages. However, it also provides enhancements to
`MIDIPacket` and `MIDIPacketList` to support building new ones and to parse them.

# Features

This package basically sets up MIDI and connects to all available inputs it finds. Connection state can be monitored by
installing a `Monitor` instance, and actual MIDI commands can be observed by installing a `Receiver` instance.
Everything else should be handle automatically by the package.

# To Use

Create a new MIDI instance passing in a name to use for the endpoints that it will create, and a unique ID that will be
assigned to the endpoints:

```
let midi = MorkAndMIDI.MIDI(clientName: "Na-Nu Na-Nu", uniqueId: 12_345)
```

Ideally, this `uniqueId` value will actually be unique to your MIDI network. However, there is no way to
guarantee that so instead one should install a `Monitor` to observe the unique ID value that is passed to
`Monitor.initialized` rouotine once initialization is complete. When there are no conflicts, this value 
will be the same as the one given in the `MIDI` constructor. If there was a conflict, you should be
given a value provided by the system.

# Processing MIDI Messages

The `Receiver` protocol defines functions that will be called for MIDI commands that arrive over USB or the network.
Since they are all optional, you only need to implement the commands you want.

Note that at the moment, SysExc (0xF0) commands are not support and will be silently ignored. I have no need for them,
but supporting them should not be too difficult a task -- you just need to buffer MIDI packets until it is complete.

# Connectivity

The `MIDI` class listens for changes to the MIDI nework and creates / destroys connections to external devices when necessary.
The `Monitor` protocol has methods you can implement to be notified when connections and/or devices change. There is also a
way to track the MIDI channel being used by an external device.

# MIDIPacket and MIDIPacketList Builders

I implemented my own version of the builders that are available for MIDIPacket and MIDIPacketList in iOS 14+. They are not
100% replacement, but they do what I need in a safe and performant manner, and they allow me to continue to support iOS 12
devices in my apps.
