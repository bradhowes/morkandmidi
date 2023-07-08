// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MorkAndMIDI",
  platforms: [.iOS(.v14), .macOS(.v11)],
  products: [
    .library(name: "MorkAndMIDI", targets: ["MorkAndMIDI"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "MorkAndMIDI", dependencies: []),
    .testTarget(name: "MorkAndMIDITests", dependencies: ["MorkAndMIDI"]),
  ]
)
