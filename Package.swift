// swift-tools-version:5.4
import PackageDescription

var packageDependencies: [Package.Dependency] = []
var calDependencies: [Target.Dependency] = ["AwsCCommon"]
var ioDependencies: [Target.Dependency] = ["AwsCCommon", "AwsCCal"]

#if os(Linux)
packageDependencies.append(.package(name: "S2N", path: "./S2N"))

ioDependencies.append(.product(name: "S2N", package: "S2N"))
calDependencies.append(.product(name: "LibCrypto", package: "S2N"))
#endif

var package = Package(name: "AwsCrt",
    platforms: [.iOS(.v11), .macOS(.v10_14)],
    products: [
      .library(name: "AwsCommonRuntimeKit", targets: ["AwsCommonRuntimeKit"]),
      .executable(name: "Elasticurl", targets: ["Elasticurl"])
    ],
    dependencies: packageDependencies
)

let excludesFromAll = ["tests", "cmake", "codebuild", "CONTRIBUTING.md",
                       "LICENSE", "format-check.sh", "NOTICE", "builder.json",
                       "sanitizer-blacklist.txt", "CMakeLists.txt", "README.md",
                       "CODE_OF_CONDUCT.md", "build-deps.sh"]

// aws-c-common config
var awsCCommonPlatformExcludes = ["source/windows", "source/android",
                                  "AWSCRTAndroidTestRunner", "docker-images", "verification",
                                  "include/aws/common/"]
awsCCommonPlatformExcludes.append(contentsOf: excludesFromAll)

#if arch(i386) || arch(x86_64)
awsCCommonPlatformExcludes.append("source/arch/arm")
// temporary cause I can't use intrensics because swiftpm doesn't like the necessary compiler flag.
awsCCommonPlatformExcludes.append("source/arch/intel")
// unsafeFlagsArray.append("-mavx512f")
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

var awsCIoPlatformExcludes = ["docs"]
awsCIoPlatformExcludes.append(contentsOf: excludesFromAll)

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

var awsCCalPlatformExcludes = ["bin", "include/aws/cal/private"]
awsCCalPlatformExcludes.append(contentsOf: excludesFromAll)

#if os(macOS)
awsCCalPlatformExcludes.append("source/windows")
awsCCalPlatformExcludes.append("source/unix")
#elseif(Windows)
awsCCalPlatformExcludes.append("source/darwin")
awsCCalPlatformExcludes.append("source/unix")
#else
awsCCalPlatformExcludes.append("source/windows")
awsCCalPlatformExcludes.append("source/darwin")
#endif

var awsCCompressionPlatformExcludes = ["source/huffman_generator/"]
awsCCompressionPlatformExcludes.append(contentsOf: excludesFromAll)
var awsCHttpPlatformExcludes = ["bin", "integration-testing", "continuous-delivery", "include/aws/http/private"]
awsCHttpPlatformExcludes.append(contentsOf: excludesFromAll)
let awsCAuthPlatformExcludes = excludesFromAll
let awsCMqttPlatformExcludes = excludesFromAll
let awsCLibCryptoPlatformExcludes = ["tests", "util/fipstools"] + excludesFromAll

let cFlags = ["-g", "-fno-omit-frame-pointer"]

package.targets = ( [
    .target(
        name: "AwsCPlatformConfig",
        path: "aws-common-runtime/config",
        publicHeadersPath: ".",
        cSettings: [
//            .unsafeFlags(cFlags)
        ]
    ),
    .target(
        name: "AWSCLibCrypto",
        path: "aws-common-runtime/aws-lc",
        exclude: awsCLibCryptoPlatformExcludes,
        cSettings: [
 //           .unsafeFlags(cFlags)
        ]
    ),
    .target(
        name: "AwsCCommon",
        dependencies: ["AwsCPlatformConfig"],
        path: "aws-common-runtime/aws-c-common",
        exclude: awsCCommonPlatformExcludes,
        cSettings: [
//            .unsafeFlags(cFlags)
        ]
    ),
    .target(
        name: "AwsCCal",
        dependencies: calDependencies,
        path: "aws-common-runtime/aws-c-cal",
        exclude: awsCCalPlatformExcludes,
        cSettings: [
//            .unsafeFlags(cFlags)
        ]
    ),
    .target(
        name: "AwsCIo",
        dependencies: ioDependencies,
        path: "aws-common-runtime/aws-c-io",
        exclude: awsCIoPlatformExcludes,
        cSettings: [
//            .unsafeFlags(cFlags)
        ]
    ),
    .target(
        name: "AwsCCompression",
        dependencies: ["AwsCCommon"],
        path: "aws-common-runtime/aws-c-compression",
        exclude: awsCCompressionPlatformExcludes,
        cSettings: [
//            .unsafeFlags(cFlags)
        ]
    ),
    .target(
        name: "AwsCHttp",
        dependencies: ["AwsCCompression", "AwsCIo", "AwsCCal", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-http",
        exclude: awsCHttpPlatformExcludes,
        cSettings: [
//            .unsafeFlags(cFlags)
        ]
    ),
    .target(
        name: "AwsCAuth",
        dependencies: ["AwsCHttp", "AwsCCompression", "AwsCCal", "AwsCIo", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-auth",
        exclude: awsCAuthPlatformExcludes,
        cSettings: [
//            .unsafeFlags(cFlags)
        ]
    ),
    .target(
        name: "AwsCMqtt",
        dependencies: ["AwsCHttp", "AwsCCompression", "AwsCIo", "AwsCCal", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-mqtt",
        exclude: awsCMqttPlatformExcludes,
        cSettings: [
            .define("AWS_MQTT_WITH_WEBSOCKETS")
//            .unsafeFlags(cFlags)
        ]
    ),
    .target(
        name: "AwsCommonRuntimeKit",
        dependencies: [ "AwsCMqtt", "AwsCAuth", "AwsCHttp", "AwsCCal", "AwsCCompression", "AwsCIo", "AwsCCommon"],
        path: "Source/AwsCommonRuntimeKit",
        swiftSettings: [
//            .unsafeFlags(["-g"]),
//            .unsafeFlags(["-Onone"], .when(configuration: .debug))
        ]
    ),
    .testTarget(
        name: "AwsCommonRuntimeKitTests",
        dependencies: ["AwsCommonRuntimeKit"],
        path: "Test",
        swiftSettings: [
//            .unsafeFlags(["-g"]),
//            .unsafeFlags(["-Onone"], .when(configuration: .debug))
        ]
    ),
    .executableTarget(
        name: "Elasticurl",
        dependencies: ["AwsCommonRuntimeKit"],
        path: "Source/Elasticurl",
        swiftSettings: [
//            .unsafeFlags(["-g"]),
//            .unsafeFlags(["-Onone"], .when(configuration: .debug))
        ]
    )
] )
