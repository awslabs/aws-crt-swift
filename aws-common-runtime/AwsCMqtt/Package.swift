// swift-tools-version:5.1

import PackageDescription
import Foundation

var package = Package(name: "AwsCMqtt",
                      products: [
                        .library(name: "aws-c-mqtt", type: .static, targets: ["aws-c-mqtt"])
                      ],
                      dependencies: [
                        .package(path: "../AwsCHttp"),
                        .package(path: "../AwsCIo"),
                        .package(path: "../AwsCCompression"),
                        .package(path: "../AwsCCommon"),
                      ]
                      )

var platformExcludes = ["include", "tests", "cmake"]

package.targets = ( [
    .target(
        name: "aws-c-mqtt",
        dependencies: ["aws-c-http", "aws-c-compression", "aws-c-io", "aws-c-common"],
        path: "aws-c-mqtt",
        exclude: platformExcludes,
        publicHeadersPath: "include",
        cSettings: [
            .headerSearchPath("include/"),
            .headerSearchPath("../platform_config/osx/x86_64/"),
            //do this to avoid having problems with the test header module export
            .define("AWS_UNSTABLE_TESTING_API=1")
        ]
    )
])

