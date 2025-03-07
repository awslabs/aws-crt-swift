// swift-tools-version:5.7
import PackageDescription

let excludesFromAll = ["tests", "cmake", "CONTRIBUTING.md",
                       "LICENSE", "format-check.py", "NOTICE", "builder.json",
                       "CMakeLists.txt", "README.md"]
var packageTargets: [Target] = []

var package = Package(name: "aws-crt-swift",
                      platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
                      products: [
                        .library(name: "AwsCommonRuntimeKit", targets: ["AwsCommonRuntimeKit"]),
                        .executable(name: "Elasticurl", targets: ["Elasticurl"])
                      ]
)

let cSettings: [CSetting] = [
    .define("DEBUG_BUILD", .when(configuration: .debug)),
    // Disable Intel VTune tracing API here since aws-crt-swift doesn't use CMake
    .define("INTEL_NO_ITTNOTIFY_API"),
    // Don't use APIs forbidden by App Stores (e.g. non-public system APIs)
    .define("AWS_APPSTORE_SAFE"),
]

/// Store any defines that will be used by Swift Tests in swiftTestSettings
var swiftTestSettings: [SwiftSetting] = []

//////////////////////////////////////////////////////////////////////
/// Configure C targets.
/// Note: We can not use unsafe flags because SwiftPM makes the target ineligible for use by other packages.
///       We are also not using any architecture based conditionals due to lack of proper cross compilation support.
/// Configure aws-c-common
//////////////////////////////////////////////////////////////////////
var awsCCommonPlatformExcludes = ["source/android",
                                  "AWSCRTAndroidTestRunner", "verification",
                                  "include/aws/common/",
                                  "scripts/appverifier_ctest.py",
                                  "scripts/appverifier_xml.py",
                                  "source/linux/system_info.c",
                                  "bin/"] + excludesFromAll

// includes arch/generic because the SwiftPM doesn't like the necessary compiler flags.
awsCCommonPlatformExcludes.append("source/arch/intel")
awsCCommonPlatformExcludes.append("source/arch/arm")
#if !os(Windows)
awsCCommonPlatformExcludes.append("source/windows")
#endif
let cSettingsCommon: [CSetting] = [
    .headerSearchPath("source/external/libcbor"),
    .define("DEBUG_BUILD", .when(configuration: .debug))
]

//////////////////////////////////////////////////////////////////////
/// aws-c-cal
//////////////////////////////////////////////////////////////////////
var calDependencies: [Target.Dependency] = ["AwsCCommon"]
#if os(Linux)
packageTargets.append( .systemLibrary(
    name: "LibCrypto",
    pkgConfig: "libcrypto",
    providers: [
        .apt(["openssl libssl-dev"]),
        .yum(["openssl openssl-devel"])
    ]
))
calDependencies.append("LibCrypto")
#endif

var awsCCalPlatformExcludes = [
    "bin",
    "include/aws/cal/private",
    "CODE_OF_CONDUCT.md",
    "ecdsa-fuzz-corpus/windows/p256_sig_corpus.txt",
    "ecdsa-fuzz-corpus/darwin/p256_sig_corpus.txt"] + excludesFromAll

#if os(Windows)
awsCCalPlatformExcludes.append("source/darwin")
awsCCalPlatformExcludes.append("source/unix")
#elseif os(Linux)
awsCCalPlatformExcludes.append("source/windows")
awsCCalPlatformExcludes.append("source/darwin")
#else  // macOS, iOS, watchOS, tvOS
awsCCalPlatformExcludes.append("source/windows")
awsCCalPlatformExcludes.append("source/unix")
#endif

//////////////////////////////////////////////////////////////////////
/// s2n-tls
//////////////////////////////////////////////////////////////////////
#if os(Linux)
let s2nExcludes = ["bin", "codebuild", "coverage", "docker-images",
                   "docs", "lib",
                   "libcrypto-build", "scram",
                   "s2n.mk", "Makefile", "stuffer/Makefile", "crypto/Makefile",
                   "tls/Makefile", "utils/Makefile", "error/Makefile", "tls/extensions/Makefile",
                   "scripts/", "codebuild", "bindings/rust", "VERSIONING.rst", "tests",
                   "cmake/s2n-config.cmake", "CMakeLists.txt", "README.md", "cmake", "NOTICE", "LICENSE"]
packageTargets.append(.target(
    name: "S2N_TLS",
    dependencies: ["LibCrypto"],
    path: "aws-common-runtime/s2n",
    exclude: s2nExcludes,
    publicHeadersPath: "api",
    cSettings: [
        .headerSearchPath("./"),
        .define("S2N_NO_PQ"),
        // This is a hack to get around the fact that S2N uses the compiler option `-include`
        // to include `s2n_prelude.h` in all .c files. Since SwiftPM doesn't support compiler flags,
        // we manually define the macros from `s2n_prelude.h`. When SwiftPM supports compiler flags
        // or building packages using CMake, this hack should be removed.
        // We are not defining `S2N_API` because we don't need to expose any symbols from S2N in crt-swift.
        .define("_S2N_PRELUDE_INCLUDED"),
        .define("S2N_BUILD_RELEASE"),
        .define("_FORTIFY_SOURCE", to: "2"),
        .define("POSIX_C_SOURCE", to: "200809L"),
    ]
))
#endif

//////////////////////////////////////////////////////////////////////
/// aws-c-io
//////////////////////////////////////////////////////////////////////
var ioDependencies: [Target.Dependency] = ["AwsCCommon", "AwsCCal"]
var awsCIoPlatformExcludes = ["docs", "CODE_OF_CONDUCT.md", "codebuild", "PKCS11.md",
                              "source/pkcs11/v2.40"] + excludesFromAll
var cSettingsIO = cSettings

#if os(Linux)
ioDependencies.append("S2N_TLS")
cSettingsIO.append(.define("USE_S2N"))
#endif

#if os(Windows)
awsCIoPlatformExcludes.append("source/posix")
awsCIoPlatformExcludes.append("source/linux")
awsCIoPlatformExcludes.append("source/s2n")
awsCIoPlatformExcludes.append("source/darwin")
cSettingsIO.append(.define("AWS_ENABLE_IO_COMPLETION_PORTS"))
swiftTestSettings.append(.define("AWS_ENABLE_IO_COMPLETION_PORTS"))
#elseif os(Linux)
awsCIoPlatformExcludes.append("source/windows")
awsCIoPlatformExcludes.append("source/bsd")
awsCIoPlatformExcludes.append("source/darwin")
cSettingsIO.append(.define("AWS_ENABLE_EPOLL"))
swiftTestSettings.append(.define("AWS_ENABLE_EPOLL"))
#else  // macOS, iOS, watchOS, tvOS
awsCIoPlatformExcludes.append("source/windows")
awsCIoPlatformExcludes.append("source/linux")
awsCIoPlatformExcludes.append("source/s2n")
cSettingsIO.append(.define("__APPLE__"))
cSettingsIO.append(.define("AWS_ENABLE_DISPATCH_QUEUE", .when(platforms: [.iOS, .tvOS, .macOS])))
cSettingsIO.append(.define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS])))
cSettingsIO.append(.define("AWS_ENABLE_KQUEUE", .when(platforms: [.macOS])))
swiftTestSettings.append(.define("__APPLE__"))
swiftTestSettings.append(.define("AWS_ENABLE_DISPATCH_QUEUE", .when(platforms: [.iOS, .tvOS, .macOS])))
swiftTestSettings.append(.define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS])))
swiftTestSettings.append(.define("AWS_ENABLE_KQUEUE", .when(platforms: [.macOS])))
#endif

//////////////////////////////////////////////////////////////////////
/// aws-c-checksums
//////////////////////////////////////////////////////////////////////
var awsCChecksumsExcludes = [
    "bin",
    "CMakeLists.txt",
    "LICENSE",
    "builder.json",
    "README.md",
    "cmake",
    "tests"]

// Hardware accelerated checksums are disabled because SwiftPM doesn't like the necessary compiler flags.
// We can add it once SwiftPM has the necessary support for CPU flags or builds C libraries
// using CMake.
// See: https://github.com/apple/swift-package-manager/issues/4555
// Also, see issue: https://github.com/awslabs/aws-sdk-swift/issues/867 before enabling hardware accelerated checksums.
// includes source/generic
awsCChecksumsExcludes.append("source/arm")
awsCChecksumsExcludes.append("source/intel")

//////////////////////////////////////////////////////////////////////
/// aws-c-sdkutils
//////////////////////////////////////////////////////////////////////
let awsCSdkUtilsPlatformExcludes = ["CODE_OF_CONDUCT.md"] + excludesFromAll

//////////////////////////////////////////////////////////////////////
/// aws-c-compression
//////////////////////////////////////////////////////////////////////
var awsCCompressionPlatformExcludes = ["source/huffman_generator/", "CODE_OF_CONDUCT.md",
                                       "codebuild"] + excludesFromAll

//////////////////////////////////////////////////////////////////////
/// aws-c-http
//////////////////////////////////////////////////////////////////////
var awsCHttpPlatformExcludes = [
    "bin",
    "integration-testing",
    "include/aws/http/private",
    "CODE_OF_CONDUCT.md",
    "codebuild/linux-integration-tests.yml"] + excludesFromAll

//////////////////////////////////////////////////////////////////////
/// aws-c-auth
//////////////////////////////////////////////////////////////////////
let awsCAuthPlatformExcludes = ["CODE_OF_CONDUCT.md"] + excludesFromAll

//////////////////////////////////////////////////////////////////////
/// aws-c-eventstreams
//////////////////////////////////////////////////////////////////////
let awsCEventStreamExcludes = [
    "bin",
    "CODE_OF_CONDUCT.md",
    "clang-tidy/run-clang-tidy.sh"] + excludesFromAll

//////////////////////////////////////////////////////////////////////
/// aws-c-mqtt
//////////////////////////////////////////////////////////////////////

let awsCMqttExcludes = [
    "bin",
    "CODE_OF_CONDUCT.md"
] + excludesFromAll

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
        cSettings: cSettingsCommon
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
        name: "AwsCChecksums",
        dependencies: ["AwsCCommon"],
        path: "aws-common-runtime/aws-checksums",
        exclude: awsCChecksumsExcludes,
        cSettings: cSettings
    ),
    .target(
        name: "AwsCEventStream",
        dependencies: ["AwsCChecksums", "AwsCCommon", "AwsCIo", "AwsCCal"],
        path: "aws-common-runtime/aws-c-event-stream",
        exclude: awsCEventStreamExcludes,
        cSettings: cSettings
    ),
    .target(
        name: "AwsCMqtt",
        dependencies: ["AwsCHttp", "AwsCCal", "AwsCIo", "AwsCCommon"],
        path: "aws-common-runtime/aws-c-mqtt",
        exclude: awsCMqttExcludes,
        cSettings: cSettings
    ),
    .systemLibrary(
        name: "LibNative"
    ),
    .target(
        name: "AwsCommonRuntimeKit",
        dependencies: [ "AwsCAuth",
                        "AwsCHttp",
                        "AwsCCal",
                        "AwsCCompression",
                        "AwsCIo",
                        "AwsCCommon",
                        "AwsCChecksums",
                        "AwsCEventStream",
                        "AwsCMqtt",
                        "LibNative"],
        path: "Source/AwsCommonRuntimeKit",
        resources: [
            .copy("PrivacyInfo.xcprivacy")
        ]
    ),
    .testTarget(
        name: "AwsCommonRuntimeKitTests",
        dependencies: ["AwsCommonRuntimeKit"],
        path: "Test/AwsCommonRuntimeKitTests",
        resources: [
            .process("Resources")
        ],
        swiftSettings: swiftTestSettings
    ),
    .executableTarget(
        name: "Elasticurl",
        dependencies: ["AwsCommonRuntimeKit"],
        path: "Source/Elasticurl"
    )
] )
package.targets = packageTargets
