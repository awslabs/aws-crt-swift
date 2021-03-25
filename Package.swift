// swift-tools-version:5.3
import PackageDescription


var calDependencies : [Target.Dependency] = ["AwsCCommon"]
var ioDependencies : [Target.Dependency] = ["AwsCCommon", "AwsCCal"]

#if os(Linux)
ioDependencies.append("S2N")
calDependencies.append("LibCrypto")
#endif

var package = Package(name: "AwsCrt",
    platforms: [.iOS(.v11), .macOS(.v10_14)],
    products: [
      .library(name: "AwsCommonRuntimeKit", targets: ["AwsCommonRuntimeKit"]),
      .executable(name: "Elasticurl", targets: ["Elasticurl"])
    ]
)

let excludesFromAll = ["tests", "cmake", "codebuild", "CONTRIBUTING.md", "LICENSE", "format-check.sh", "NOTICE", "builder.json", "sanitizer-blacklist.txt", "CMakeLists.txt", "README.md", "CODE_OF_CONDUCT.md", "build-deps.sh"]

// aws-c-common config
var awsCCommonPlatformExcludes = ["source/windows", "source/android", "AWSCRTAndroidTestRunner", "docker-images", "verification", "include/aws/common/"]
awsCCommonPlatformExcludes.append(contentsOf: excludesFromAll)

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

var awsCCalPlatformExcludes = ["tests", "cmake"]
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

var awsS2nExcludes = ["bin", "cmake", "codebuild", "coverage", "docker-images", "docs", "lib", "pq-crypto", "libcrypto-build", "scram", "tests", "s2n.mk", "Makefile", "stuffer/Makefile", "crypto/Makefile", "tls/Makefile", "utils/Makefile", "error/Makefile", "extensions/Makefile", "tls/extensions/Makefile", "codecov.yml", "scripts/"]
awsS2nExcludes.append(contentsOf: excludesFromAll)

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
    ),
    .target(
        name: "S2N",
        dependencies: ["LibCrypto"],
        path: "S2N/s2n",
        exclude: awsS2nExcludes,
        publicHeadersPath: "api",
        cSettings: [
            .headerSearchPath("./"),
            .define("POSIX_C_SOURCE=200809L"),
            .define("S2N_NO_PQ"),
        ]
    ),
    .systemLibrary(
        name: "LibCrypto",
        pkgConfig: "libcrypto",
        providers: [
            .apt(["openssl libssl-dev"])
//add this back when swift pm get's their crap together \\  .yum(["openssl openssl-devel"])
        ]
    )
] )



