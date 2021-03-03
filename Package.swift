// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "monkey",
  dependencies: [],
  targets: [
    .target(
      name: "monkey",
      dependencies: [],
      exclude: []),
    .testTarget(
      name: "monkey-tests",
      dependencies: ["monkey"]),
  ]
)
