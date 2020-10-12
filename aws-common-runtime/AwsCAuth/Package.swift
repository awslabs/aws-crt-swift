// swift-tools-version:5.1

import PackageDescription
import Foundation

var package = Package(name: "AwsCAuth",
                      products: [
                        .library(name: "aws-c-auth", type: .static, targets: ["aws-c-auth"])
                      ],
                      dependencies: [
                        .package(path: "../AwsCHttp"),
                        .package(path: "../AwsCCompression"),
                        .package(path: "../AwsCCal"),
                        .package(path: "../AwsCIo"),
                        .package(path: "../AwsCCommon"),
                      ]
                      )

var platformExcludes = ["include", "tests"]

package.targets = ( [
    .target(
        name: "aws-c-auth",
        dependencies: ["aws-c-http", "aws-c-compression", "aws-c-cal", "aws-c-io", "aws-c-common"],
        path: "aws-c-auth",
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

