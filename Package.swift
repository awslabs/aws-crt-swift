// swift-tools-version:5.3
import PackageDescription

var packageDependencies: [String] = []
var calDependencies = ["AwsCCommon"]
var ioDependencies = ["AwsCCommon", "AwsCCal"]

#if os(Linux)
let libCryptoPackage = Package(
    name: "LibCrypto",
    products: [
        .library(
            name: "LibCrypto",
            targets: ["LibCrypto"]
        )
    ],
    targets: [
        .systemLibrary(
            name: "LibCrypto",
            pkgConfig: "openssl",
            providers: [
                .apt(["openssl libssl-dev"]),
                .yum(["openssl openssl-devel"]),
            ]
        )
    ])

packageDependencies.append("LibCrypto")
calDependencies.append("LibCrypto")
ioDependencies.append("LibCrypto")

let s2nPackage = Package(
    name: "S2N",
    products: [
        .library(
            name: "S2N",
            targets: ["S2N"]
        )
    ],
    dependencies: [libCryptoPackage],
    targets: [
        .target(
            name: "S2N",
            dependencies: ["LibCrypto"],
            path: "aws-common-runtime/s2n",
            exclude: ["bin", "cmake", "codebuild", "coverage", "docker-images", "docs", "lib", "libcrypto-build", "scram", "tests"],
            publicHeadersPath: "api"
        )
    ]
)

packageDependencies.append("S2N")
calDependencies.append("S2N")
ioDependencies.append("S2N")
#endif

var package = Package(name: "AwsCrt",
    platforms: [.iOS(.v11), .macOS(.v10_14)],
    products: [
      .library(name: "AwsCommonRuntimeKit", targets: ["AwsCommonRuntimeKit"]),
      .executable(name: "Elasticurl", targets: ["Elasticurl"])
    ],
    dependencies: packageDependencies
)

// aws-c-common config
var awsCCommonPlatformExcludes = ["source/windows", "source/android", "AWSCRTAndroidTestRunner", "cmake", "codebuild", "docker-images", "tests", "verification"]
//var unsafeFlagsArray: [String] = []

#if arch(i386) || arch(x86_64)
awsCCommonPlatformExcludes.append("source/arch/arm")
//temporary cause I can't use intrensics because swiftpm doesn't like the necessary compiler flag.
awsCCommonPlatformExcludes.append("source/arch/intel")
//unsafeFlagsArray.append("-mavx512f")
#elseif arch(arm64)
awsCCommonPlatformExcludes.append("source/arch/intel")
#else
awsCCommonPlatformExcludes.append("source/arch/intel")
awsCCommonPlatformExcludes.append("source/arch/arm")
#endif

#if !os(Windows)
awsCCommonPlatformExcludes.append("source/arch/intel/msvc")
awsCCommonPlatformExcludes.append("source/arch/arm/msvc")
#else
awsCCommonPlatformExcludes.append("source/arch/intel/asm")
awsCCommonPlatformExcludes.append("source/arch/arm/asm")
#endif

var awsCIoPlatformExcludes = ["tests", "cmake", "docs"]

#if os(macOS)
awsCIoPlatformExcludes.append("source/windows")
awsCIoPlatformExcludes.append("source/linux")
awsCIoPlatformExcludes.append("source/s2n")
#elseif(Windows)
awsCIoPlatformExcludes.append("source/posix")
awsCIoPlatformExcludes.append("source/linux")
awsCIoPlatformExcludes.append("source/s2n")
awsCIoPlatformExcludes.append("source/darwin")
#else
awsCIoPlatformExcludes.append("source/windows")
awsCIoPlatformExcludes.append("source/bsd")
awsCIoPlatformExcludes.append("source/darwin")
#endif

var awsCCalPlatformExcludes = ["tests", "cmake"]

#if os(macOS)
awsCCalPlatformExcludes.append("source/windows")
awsCCalPlatformExcludes.append("source/unix")
#elseif(Windows)
awsCCalPlatformExcludes.append("source/darin")
awsCCalPlatformExcludes.append("source/unix")
#else
awsCCalPlatformExcludes.append("source/windows")
awsCCalPlatformExcludes.append("source/darwin")
#endif

var awsCCompressionPlatformExcludes = ["tests", "cmake", "codebuild", "source/huffman_generator/"]
var awsCHttpPlatformExcludes = ["tests", "bin", "integration-testing", "continuous-delivery", "cmake", "codebuild"]
var awsCAuthPlatformExcludes = ["tests"]
var awsCMqttPlatformExcludes = ["tests", "cmake"]

package.targets = ( [
    .target(
        name: "AwsCPlatformConfig",
        path: "aws-common-runtime/config",
        publicHeadersPath: "."),
    .target(
        name: "AwsCCommon",
        dependencies: ["AwsCPlatformConfig"],
        path: "aws-common-runtime/aws-c-common",
        exclude: awsCCommonPlatformExcludes),
    .target(
        name: "AwsCCal",
        dependencies: calDependencies,
        path: "aws-common-runtime/aws-c-cal",
        exclude: awsCCalPlatformExcludes),
    .target(
        name: "AwsCIo",
        dependencies: ioDependencies,
        path: "aws-common-runtime/aws-c-io",
        exclude: awsCIoPlatformExcludes),
    .target(
        name: "AwsCCompression",
        dependencies: ["AwsCCommon"],
        path: "aws-common-runtime/aws-c-compression",
        exclude: awsCCompressionPlatformExcludes
    ),
    .target(
        name: "AwsCHttp",
        dependencies: ["AwsCCompression", "AwsCIo", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-http",
        exclude: awsCHttpPlatformExcludes
    ),
    .target(
        name: "AwsCAuth",
        dependencies: ["AwsCHttp", "AwsCCompression", "AwsCCal", "AwsCIo", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-auth",
        exclude: awsCAuthPlatformExcludes
    ),
    .target(
        name: "AwsCMqtt",
        dependencies: ["AwsCHttp", "AwsCCompression", "AwsCIo", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-mqtt",
        exclude: awsCMqttPlatformExcludes
    ),
    .target(
        name: "AwsCommonRuntimeKit",
        dependencies: [ "AwsCMqtt", "AwsCAuth", "AwsCHttp", "AwsCCal", "AwsCCompression", "AwsCIo", "AwsCCommon"],
        path: "Source/AwsCommonRuntimeKit"
    ),
    .testTarget(
        name: "AwsCommonRuntimeKitTests",
        dependencies: ["AwsCommonRuntimeKit"],
        path: "Test"
    ),
    .target(
        name: "Elasticurl",
        dependencies: ["AwsCommonRuntimeKit"],
        path: "Source/Elasticurl"
    )
] )



