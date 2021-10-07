// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BareMIDI",
  platforms: [.iOS(.v12)],
  products: [
    .library(name: "BareMIDI", targets: ["BareMIDI"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "BareMIDI", dependencies: []),
    .testTarget(name: "BareMIDITests", dependencies: ["BareMIDI"]),
  ]
)
