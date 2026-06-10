// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "ImageMorphing",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "ImageMorphing",
      targets: ["ImageMorphing"]
    )
  ],
  targets: [
    .target(
      name: "ImageMorphing"
    ),
    .testTarget(
      name: "ImageMorphingTests",
      dependencies: ["ImageMorphing"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
