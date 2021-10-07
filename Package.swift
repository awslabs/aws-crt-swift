// swift-tools-version:5.4
import PackageDescription

let excludesFromAll = ["tests", "cmake", "CONTRIBUTING.md",
                       "LICENSE", "format-check.sh", "NOTICE", "builder.json",
                        "CMakeLists.txt", "README.md"]
var packageTargets: [Target] = []

var package = Package(name: "AwsCrt",
    platforms: [.iOS(.v11), .macOS(.v10_14)],
    products: [
      .library(name: "AwsCommonRuntimeKit", targets: ["AwsCommonRuntimeKit"]),
      .executable(name: "Elasticurl", targets: ["Elasticurl"])
    ]
)

var calDependencies: [Target.Dependency] = ["AwsCCommon"]
var ioDependencies: [Target.Dependency] = ["AwsCCommon", "AwsCCal"]

#if os(Linux)
packageTargets.append( .systemLibrary(
            name: "LibCrypto",
            pkgConfig: "libcrypto",
            providers: [
                .apt(["openssl libssl-dev"]),
                .yum(["openssl openssl-devel"])
            ]
        ))
 // add pq-crypto back after adding in platform and chipset detection
let s2nExcludes = excludesFromAll + ["bin", "codebuild", "coverage", "docker-images",
                      "docs", "lib", "pq-crypto/bike_r1", "pq-crypto/bike_r2",
                      "pq-crypto/bike_r3", "pq-crypto/kyber_90s_r2", "pq-crypto/kyber_r3",
                      "pq-crypto/kyber_r2", "pq-crypto/sike_r1", "pq-crypto/sike_r2",
                      "pq-crypto/README.md", "pq-crypto/Makefile", "pq-crypto/s2n_pq_asm.mk",
                      "libcrypto-build", "scram",
                      "s2n.mk", "Makefile", "stuffer/Makefile", "crypto/Makefile",
                      "tls/Makefile", "utils/Makefile", "error/Makefile",
                      "extensions/Makefile", "tls/extensions/Makefile",
                      "codecov.yml", "scripts/", "codebuild", "format-check.sh", "sanitizer-blacklist.txt",
                      "CODE_OF_CONDUCT.md", "build-deps.sh"]
packageTargets.append(.target(
            name: "S2N",
            dependencies: ["LibCrypto"],
            path: "aws-common-runtime/s2n",
            exclude: s2nExcludes,
            publicHeadersPath: "api",
            cSettings: [
                .headerSearchPath("./"),
                .define("POSIX_C_SOURCE=200809L"),
                .define("S2N_NO_PQ")
            ]
        ))
ioDependencies.append("S2N")
calDependencies.append("LibCrypto")
#endif

// aws-c-common config
var awsCCommonPlatformExcludes = ["source/windows", "source/android",
                                  "AWSCRTAndroidTestRunner", "docker-images", "verification",
                                  "include/aws/common/", "sanitizer-blacklist.txt"] + excludesFromAll

#if arch(i386) || arch(x86_64)
awsCCommonPlatformExcludes.append("source/arch/arm")
// temporary cause I can't use intrensics because swiftpm doesn't like the necessary compiler flag.
awsCCommonPlatformExcludes.append("source/arch/intel")
// unsafeFlagsArray.append("-mavx512f")
#elseif arch(arm64)
awsCCommonPlatformExcludes.append("source/arch/intel")
awsCCommonPlatformExcludes.append("source/arch/generic")
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

var awsCIoPlatformExcludes = ["docs", "CODE_OF_CONDUCT.md"] + excludesFromAll

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

var awsCCalPlatformExcludes = ["bin", "include/aws/cal/private", "CODE_OF_CONDUCT.md", "sanitizer-blacklist.txt"] + excludesFromAll

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

var awsCCompressionPlatformExcludes = ["source/huffman_generator/", "CODE_OF_CONDUCT.md",
                                       "codebuild"] + excludesFromAll

var awsCHttpPlatformExcludes = ["bin", "integration-testing", "include/aws/http/private",
                                "CODE_OF_CONDUCT.md", "sanitizer-blacklist.txt"] + excludesFromAll
let awsCAuthPlatformExcludes = ["CODE_OF_CONDUCT.md"] + excludesFromAll
let awsCMqttPlatformExcludes = ["bin", "CODE_OF_CONDUCT.md"] + excludesFromAll

let cFlags = ["-g", "-fno-omit-frame-pointer"]

packageTargets.append(contentsOf: [
    .target(
        name: "AwsCPlatformConfig",
        path: "aws-common-runtime/config",
        publicHeadersPath: ".",
        cSettings: [
//            .unsafeFlags(cFlags)
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

package.targets = packageTargets
