// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AnimalsData",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .macCatalyst(.v17),
  ],
  products: [
    .library(
      name: "AnimalsData",
      targets: ["AnimalsData"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-algorithms.git",
      from: "1.2.0"
    ),
    .package(
      url: "https://github.com/apple/swift-async-algorithms.git",
      from: "1.0.3"
    ),
    .package(
      url: "https://github.com/apple/swift-collections.git",
      from: "1.1.4"
    ),
    .package(
      url: "https://github.com/swift-cowbox/swift-cowbox.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/vapor/vapor.git",
      from: "4.111.1"
    ),
    .package(
      name: "ImmutableData",
      path: "../.."
    ),
    .package(
      name: "Services",
      path: "../Services"
    ),
  ],
  targets: [
    .target(
      name: "AnimalsData",
      dependencies: [
        .product(
          name: "Collections",
          package: "swift-collections"
        ),
        .product(
          name: "CowBox",
          package: "swift-cowbox"
        ),
        .product(
          name: "ImmutableData",
          package: "ImmutableData"
        ),
      ]
    ),
    .executableTarget(
      name: "AnimalsDataClient",
      dependencies: [
        "AnimalsData",
        "Services",
      ],
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate",
          "-Xlinker", "__TEXT",
          "-Xlinker", "__info_plist",
          "-Xlinker", "Resources/AnimalsDataClient/Info.plist",
        ])
      ]
    ),
    .executableTarget(
      name: "AnimalsDataServer",
      dependencies: [
        .product(
          name: "AsyncAlgorithms",
          package: "swift-async-algorithms"
        ),
        .product(
          name: "Vapor",
          package: "vapor",
          condition: .when(platforms: [.macOS])
        ),
        "AnimalsData",
      ],
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate",
          "-Xlinker", "__TEXT",
          "-Xlinker", "__info_plist",
          "-Xlinker", "Resources/AnimalsDataServer/Info.plist",
        ])
      ]
    ),
    .testTarget(
      name: "AnimalsDataTests",
      dependencies: [
        .product(
          name: "Algorithms",
          package: "swift-algorithms"
        ),
        "AnimalsData",
        .product(
          name: "AsyncSequenceTestUtils",
          package: "ImmutableData"
        ),
      ]
    ),
  ]
)
