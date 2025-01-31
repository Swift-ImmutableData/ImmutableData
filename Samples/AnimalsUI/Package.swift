// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AnimalsUI",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .macCatalyst(.v17),
  ],
  products: [
    .library(
      name: "AnimalsUI",
      targets: ["AnimalsUI"]
    )
  ],
  dependencies: [
    .package(
      name: "AnimalsData",
      path: "../AnimalsData"
    ),
    .package(
      name: "ImmutableData",
      path: "../.."
    ),
  ],
  targets: [
    .target(
      name: "AnimalsUI",
      dependencies: [
        "AnimalsData",
        .product(
          name: "ImmutableUI",
          package: "ImmutableData"
        ),
      ]
    )
  ]
)
