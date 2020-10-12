// swift-tools-version:5.1

import PackageDescription
import Foundation

var package = Package(name: "AwsCIo",
                      products: [
                        .library(name: "aws-c-io", type: .static, targets: ["aws-c-io"])
                      ],
                      dependencies: [
                        .package(path: "../AwsCCommon")
                      ]
                      )

var platformExcludes = ["include", "tests", "cmake", "docs"]

#if os(macOS)
platformExcludes.append("source/windows")
platformExcludes.append("source/linux")
platformExcludes.append("source/s2n")
#elseif(Windows)
platformExcludes.append("source/posix")
platformExcludes.append("source/linux")
platformExcludes.append("source/s2n")
platformExcludes.append("source/darwin")
#else
platformExcludes.append("source/windows")
platformExcludes.append("source/s2n")
platformExcludes.append("source/darwin")
#endif

package.targets = ( [
    .target(
        name: "aws-c-io",
        dependencies: ["aws-c-common"],
        path: "aws-c-io",
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

