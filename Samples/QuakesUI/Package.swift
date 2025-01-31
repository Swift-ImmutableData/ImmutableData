// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "QuakesUI",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .macCatalyst(.v17),
  ],
  products: [
    .library(
      name: "QuakesUI",
      targets: ["QuakesUI"]
    )
  ],
  dependencies: [
    .package(
      name: "QuakesData",
      path: "../QuakesData"
    ),
    .package(
      name: "ImmutableData",
      path: "../.."
    ),
  ],
  targets: [
    .target(
      name: "QuakesUI",
      dependencies: [
        "QuakesData",
        .product(
          name: "ImmutableUI",
          package: "ImmutableData"
        ),
      ]
    )
  ]
)
