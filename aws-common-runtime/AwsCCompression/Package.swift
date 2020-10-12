// swift-tools-version:5.1

import PackageDescription
import Foundation

var package = Package(name: "AwsCCompression",
                      products: [
                        .library(name: "aws-c-compression", type: .static, targets: ["aws-c-compression"])
                      ],
                      dependencies: [
                        .package(path: "../AwsCCommon")
                      ]
                      )

var platformExcludes = ["include", "tests", "cmake", "codebuild"]

package.targets = ( [
    .target(
        name: "aws-c-compression",
        dependencies: ["aws-c-common"],
        path: "aws-c-compression",
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

