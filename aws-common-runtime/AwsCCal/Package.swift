// swift-tools-version:5.1

import PackageDescription
import Foundation

var package = Package(name: "AwsCCal",
                      products: [
                        .library(name: "aws-c-cal", type: .static, targets: ["aws-c-cal"])
                      ],
                      dependencies: [
                        .package(path: "../AwsCCommon")
                      ]
                      )

var platformExcludes = ["include", "tests", "cmake"]

#if os(macOS)
platformExcludes.append("source/windows")
platformExcludes.append("source/unix")
#elseif(Windows)
platformExcludes.append("source/darin")
platformExcludes.append("source/unix")
#else
platformExcludes.append("source/windows")
platformExcludes.append("source/darwin")
#endif

package.targets = ( [
    .target(
        name: "aws-c-cal",
        dependencies: ["aws-c-common"],
        path: "aws-c-cal",
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

