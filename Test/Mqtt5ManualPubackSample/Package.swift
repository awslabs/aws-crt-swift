// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Mqtt5ManualPubackSample",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
  ],
  products: [
    .executable(name: "Mqtt5ManualPubackSample", targets: ["Mqtt5ManualPubackSample"])
  ],
  dependencies: [
    .package(path: "../../"),
    .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.2.3"),
  ],
  targets: [
    .executableTarget(
      name: "Mqtt5ManualPubackSample",
      dependencies: [
        .product(name: "AwsCommonRuntimeKit", package: "aws-crt-swift"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: ".")
  ]
)
