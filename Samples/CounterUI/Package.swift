// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "CounterUI",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .macCatalyst(.v17),
  ],
  products: [
    .library(
      name: "CounterUI",
      targets: ["CounterUI"]
    )
  ],
  dependencies: [
    .package(
      name: "CounterData",
      path: "../CounterData"
    ),
    .package(
      name: "ImmutableData",
      path: "../.."
    ),
  ],
  targets: [
    .target(
      name: "CounterUI",
      dependencies: [
        "CounterData",
        .product(
          name: "ImmutableUI",
          package: "ImmutableData"
        ),
      ]
    )
  ]
)
