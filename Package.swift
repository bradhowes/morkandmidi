// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SimplyMIDI",
  platforms: [.iOS(.v12)],
  products: [
    .library(name: "SimplyMIDI", targets: ["SimplyMIDI"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "SimplyMIDI", dependencies: []),
    .testTarget(name: "SimplyMIDITests", dependencies: ["SimplyMIDI"]),
  ]
)
