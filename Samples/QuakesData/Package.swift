// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "QuakesData",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .macCatalyst(.v17),
  ],
  products: [
    .library(
      name: "QuakesData",
      targets: ["QuakesData"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-algorithms.git",
      from: "1.2.0"
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
      name: "QuakesData",
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
      name: "QuakesDataClient",
      dependencies: [
        "QuakesData",
        "Services",
      ],
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate",
          "-Xlinker", "__TEXT",
          "-Xlinker", "__info_plist",
          "-Xlinker", "Resources/QuakesDataClient/Info.plist",
        ])
      ]
    ),
    .testTarget(
      name: "QuakesDataTests",
      dependencies: [
        .product(
          name: "Algorithms",
          package: "swift-algorithms"
        ),
        .product(
          name: "AsyncSequenceTestUtils",
          package: "ImmutableData"
        ),
        "QuakesData",
      ]
    ),
  ]
)
