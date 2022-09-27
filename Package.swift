// swift-tools-version:5.5
import PackageDescription

let excludesFromAll = ["tests", "cmake", "CONTRIBUTING.md",
                       "LICENSE", "format-check.sh", "NOTICE", "builder.json",
                        "CMakeLists.txt", "README.md"]
var packageTargets: [Target] = []

var package = Package(name: "AwsCrt",
                      platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
                      products: [
                        .library(name: "AwsCommonRuntimeKit", targets: ["AwsCommonRuntimeKit"]),
                        .executable(name: "Elasticurl", targets: ["Elasticurl"])
                      ],
                      dependencies: [.package(url: "https://github.com/apple/swift-collections", from: "1.0.2")]
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
let s2nExcludes = ["bin", "codebuild", "coverage", "docker-images",
                   "docs", "lib", "pq-crypto/kyber_r3",
                   "pq-crypto/README.md", "pq-crypto/Makefile", "pq-crypto/s2n_pq_asm.mk",
                   "libcrypto-build", "scram",
                   "s2n.mk", "Makefile", "stuffer/Makefile", "crypto/Makefile",
                   "tls/Makefile", "utils/Makefile", "error/Makefile", "tls/extensions/Makefile",
                   "scripts/", "codebuild", "bindings/rust", "VERSIONING.rst", "tests",
                   "cmake/s2n-config.cmake", "CMakeLists.txt", "README.md", "cmake", "NOTICE", "LICENSE"]
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

var awsCIoPlatformExcludes = ["docs", "CODE_OF_CONDUCT.md", "codebuild", "PKCS11.md", "THIRD-PARTY-LICENSES.txt",
                              "source/pkcs11/v2.40"] + excludesFromAll

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

let awsCSdkUtilsPlatformExcludes = ["CODE_OF_CONDUCT.md"] + excludesFromAll

var awsCCompressionPlatformExcludes = ["source/huffman_generator/", "CODE_OF_CONDUCT.md",
                                       "codebuild"] + excludesFromAll

var awsCHttpPlatformExcludes = ["bin", "integration-testing", "include/aws/http/private",
                                "CODE_OF_CONDUCT.md", "sanitizer-blacklist.txt", "codebuild/linux-integration-tests.yml"] + excludesFromAll
let awsCAuthPlatformExcludes = ["CODE_OF_CONDUCT.md"] + excludesFromAll
let awsCMqttPlatformExcludes = ["bin", "CODE_OF_CONDUCT.md"] + excludesFromAll

let cFlags = ["-g", "-fno-omit-frame-pointer"]
let cSettings: [CSetting] = [
//    .unsafeFlags(cFlags),
    .define("DEBUG_BUILD", .when(configuration: .debug))
]

var cSettingsIO = cSettings
#if os(Linux)
cSettingsIO.append(.define("USE_S2N"))
#endif

packageTargets.append(contentsOf: [
    .target(
        name: "AwsCPlatformConfig",
        path: "aws-common-runtime/config",
        publicHeadersPath: ".",
        cSettings: cSettings
    ),
    .target(
        name: "AwsCCommon",
        dependencies: ["AwsCPlatformConfig"],
        path: "aws-common-runtime/aws-c-common",
        exclude: awsCCommonPlatformExcludes,
        cSettings: cSettings
    ),
    .target(
        name: "AwsCSdkUtils",
        dependencies: ["AwsCCommon"],
        path: "aws-common-runtime/aws-c-sdkutils",
        exclude: awsCSdkUtilsPlatformExcludes,
        cSettings: cSettings
    ),
    .target(
        name: "AwsCCal",
        dependencies: calDependencies,
        path: "aws-common-runtime/aws-c-cal",
        exclude: awsCCalPlatformExcludes,
        cSettings: cSettings
    ),
    .target(
        name: "AwsCIo",
        dependencies: ioDependencies,
        path: "aws-common-runtime/aws-c-io",
        exclude: awsCIoPlatformExcludes,
        cSettings: cSettingsIO
    ),
    .target(
        name: "AwsCCompression",
        dependencies: ["AwsCCommon"],
        path: "aws-common-runtime/aws-c-compression",
        exclude: awsCCompressionPlatformExcludes,
        cSettings: cSettings
    ),
    .target(
        name: "AwsCHttp",
        dependencies: ["AwsCCompression", "AwsCIo", "AwsCCal", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-http",
        exclude: awsCHttpPlatformExcludes,
        cSettings: cSettings
    ),
    .target(
        name: "AwsCAuth",
        dependencies: ["AwsCHttp", "AwsCCompression", "AwsCCal", "AwsCIo", "AwsCSdkUtils", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-auth",
        exclude: awsCAuthPlatformExcludes,
        cSettings: cSettings
    ),
    .target(
        name: "AwsCMqtt",
        dependencies: ["AwsCHttp", "AwsCCompression", "AwsCIo", "AwsCCal", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-mqtt",
        exclude: awsCMqttPlatformExcludes,
        cSettings: cSettings + [
            .define("AWS_MQTT_WITH_WEBSOCKETS")
        ]
    ),
    .target(
        name: "AwsCommonRuntimeKit",
        dependencies: [ "AwsCMqtt",
                        "AwsCAuth",
                        "AwsCHttp",
                        "AwsCCal",
                        "AwsCCompression",
                        "AwsCIo",
                        "AwsCCommon",
                        .product(name: "Collections", package: "swift-collections")],
        path: "Source/AwsCommonRuntimeKit",
        swiftSettings: [
//            .unsafeFlags(["-g"]),
//            .unsafeFlags(["-Onone"], .when(configuration: .debug))
        ]
    ),
    .testTarget(
        name: "AwsCommonRuntimeKitTests",
        dependencies: ["AwsCommonRuntimeKit"],
        path: "Test/AwsCommonRuntimeKitTests",
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
