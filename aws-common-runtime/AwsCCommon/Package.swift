// swift-tools-version:5.1

import PackageDescription
import Foundation

var package = Package(name: "AwsCCommon", 
					  products: [ 
                        .library(name: "aws-c-common", type: .static, targets: ["aws-c-common"])
					  ])

var platformExcludes = ["include", "source/windows", "source/android", "AWSCRTAndroidTestRunner", "cmake", "codebuild", "docker-images", "tests", "verification"]
//var unsafeFlagsArray: [String] = []

#if arch(i386) || arch(x86_64)
platformExcludes.append("source/arch/arm")
//temporary cause I can't use intrensics because swiftpm doesn't like the necessary compiler flag.
platformExcludes.append("source/arch/intel")
//unsafeFlagsArray.append("-mavx512f")
#elseif arch(arm64)
platformExcludes.append("source/arch/intel")
#else
platformExcludes.append("source/arch/intel")
platformExcludes.append("source/arch/arm")
#endif

#if !os(Windows)
platformExcludes.append("source/arch/intel/msvc")
platformExcludes.append("source/arch/arm/msvc")
#else
platformExcludes.append("source/arch/intel/asm")
platformExcludes.append("source/arch/arm/asm")
#endif


package.targets = ( [
    .target(
        name: "aws-c-common",
        path: "aws-c-common",
        exclude: platformExcludes,
        publicHeadersPath: "include",
        cSettings: [
        .headerSearchPath("../platform_config/osx/x86_64/"),
        .headerSearchPath("include/"),
        //.unsafeFlags(unsafeFlagsArray),
        ]
    )
])
