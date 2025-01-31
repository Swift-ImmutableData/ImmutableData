// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "CounterData",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .macCatalyst(.v17),
  ],
  products: [
    .library(
      name: "CounterData",
      targets: ["CounterData"]
    )
  ],
  targets: [
    .target(
      name: "CounterData"
    ),
    .testTarget(
      name: "CounterDataTests",
      dependencies: ["CounterData"]
    ),
  ]
)
