// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "ImmutableData",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .macCatalyst(.v17),
  ],
  products: [
    .library(
      name: "AsyncSequenceTestUtils",
      targets: ["AsyncSequenceTestUtils"]
    ),
    .library(
      name: "ImmutableData",
      targets: ["ImmutableData"]
    ),
    .library(
      name: "ImmutableUI",
      targets: ["ImmutableUI"]
    ),
  ],
  targets: [
    .target(
      name: "AsyncSequenceTestUtils"
    ),
    .target(
      name: "ImmutableData"
    ),
    .target(
      name: "ImmutableUI",
      dependencies: ["ImmutableData"]
    ),
    .testTarget(
      name: "AsyncSequenceTestUtilsTests",
      dependencies: ["AsyncSequenceTestUtils"]
    ),
    .testTarget(
      name: "ImmutableDataTests",
      dependencies: ["ImmutableData"]
    ),
    .testTarget(
      name: "ImmutableUITests",
      dependencies: [
        "AsyncSequenceTestUtils",
        "ImmutableUI",
      ]
    ),
  ]
)
