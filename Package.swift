// swift-tools-version:5.1

import PackageDescription

var package = Package(name: "AwsCrt",
                      products: [
                        .library(name: "AwsCommonRuntimeKit", targets: ["AwsCommonRuntimeKit"]),
                      ],
                      dependencies: [
                        .package(path: "aws-common-runtime/AwsCCommon"),
                        .package(path: "aws-common-runtime/AwsCIo"),
                        .package(path: "aws-common-runtime/AwsCCompression"),
                        .package(path: "aws-common-runtime/AwsCHttp"),
                        .package(path: "aws-common-runtime/AwsCCal"),
                        .package(path: "aws-common-runtime/AwsCAuth"),
                        .package(path: "aws-common-runtime/AwsCMqtt")
                        ],
                      targets: [
                        .target(
                        name: "AwsCommonRuntimeKit",
                        dependencies: [
                            "aws-c-mqtt",
                            "aws-c-auth",
                            "aws-c-http",
                            "aws-c-cal",
                            "aws-c-compression",
                            "aws-c-io",
                            "aws-c-common"
                            ])
                       ]
                       )
