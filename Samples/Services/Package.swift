// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Services",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
  ],
  products: [
    .library(
      name: "Services",
      targets: ["Services"]
    )
  ],
  targets: [
    .target(
      name: "Services"
    ),
    .testTarget(
      name: "ServicesTests",
      dependencies: ["Services"]
    ),
  ]
)
