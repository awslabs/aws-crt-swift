// swift-tools-version:5.1

import PackageDescription
import Foundation

var package = Package(name: "AwsCHttp",
                      products: [
                        .library(name: "aws-c-http", type: .static, targets: ["aws-c-http"])
                      ],
                      dependencies: [
                        .package(path: "../AwsCIo"),
                        .package(path: "../AwsCCompression"),
                        .package(path: "../AwsCCommon"),
                      ]
                      )

var platformExcludes = ["include", "tests", "bin", "integration-testing", "continuous-delivery", "cmake", "codebuild"]

package.targets = ( [
    .target(
        name: "aws-c-http",
        dependencies: ["aws-c-compression", "aws-c-io", "aws-c-common"],
        path: "aws-c-http",
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

