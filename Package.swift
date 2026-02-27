// swift-tools-version:5.9
import PackageDescription

let excludesFromAll = [
  "tests", "cmake", "CONTRIBUTING.md",
  "LICENSE", "format-check.py", "NOTICE", "builder.json",
  "CMakeLists.txt", "README.md",
]
var packageTargets: [Target] = []

var package = Package(
  name: "aws-crt-swift",
  platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
  products: [
    .library(name: "AwsCommonRuntimeKit", targets: ["AwsCommonRuntimeKit"])
  ]
)

let cSettings: [CSetting] = [
  .define("DEBUG_BUILD", .when(configuration: .debug)),
  .define("INTEL_NO_ITTNOTIFY_API"),
  .define("AWS_APPSTORE_SAFE"),
  .define("__ANDROID__", .when(platforms: [.android])),
]

/// Store any defines that will be used by Swift Tests in swiftTestSettings
var swiftTestSettings: [SwiftSetting] = []

//////////////////////////////////////////////////////////////////////
/// Configure C targets.
/// Note: We can not use unsafe flags because SwiftPM makes the target ineligible for use by other packages.
///       We are also not using any architecture based conditionals due to lack of proper cross compilation support.
///
/// Platform-specific source files are handled via wrapper targets (*_Platform, *_Android)
/// that use C preprocessor guards (#ifdef __APPLE__, #ifdef __linux__, etc.) to conditionally
/// include the correct source files. This avoids relying on #if os() in Package.swift, which
/// evaluates on the HOST platform and breaks cross-compilation scenarios.
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
// MARK: - aws-c-common
//////////////////////////////////////////////////////////////////////
var awsCCommonPlatformExcludes =
  [
    "source/android",
    "AWSCRTAndroidTestRunner", "verification",
    "include/aws/common/",
    "scripts/appverifier_ctest.py",
    "scripts/appverifier_xml.py",
    "source/linux/system_info.c",
    "bin/",
  ] + excludesFromAll

// includes arch/generic because the SwiftPM doesn't like the necessary compiler flags.
awsCCommonPlatformExcludes.append("source/arch/intel")
awsCCommonPlatformExcludes.append("source/arch/arm")
#if !os(Windows)
  awsCCommonPlatformExcludes.append("source/windows")
#endif
#if !os(Linux)
  awsCCommonPlatformExcludes.append("source/linux")
#else
  awsCCommonPlatformExcludes.append("source/platform_fallback_stubs/file_direct_io.c")
#endif

let cSettingsCommon: [CSetting] = [
  .headerSearchPath("source/external/libcbor"),
  .define("DEBUG_BUILD", .when(configuration: .debug)),
  .define("__ANDROID__", .when(platforms: [.android])),
]

//////////////////////////////////////////////////////////////////////
// MARK: - aws-c-cal
//
// Platform sources (source/darwin, source/unix, source/windows) are
// excluded from the main target and compiled via AwsCCal_Platform
// wrapper target using preprocessor guards.
//////////////////////////////////////////////////////////////////////
let awsCCalPlatformExcludes = [
  "bin",
  "include/aws/cal/private",
  "source/shared/ed25519.c",
  "source/shared/lccrypto_common.c",
  "CODE_OF_CONDUCT.md",
  "ecdsa-fuzz-corpus/windows/p256_sig_corpus.txt",
  "ecdsa-fuzz-corpus/darwin/p256_sig_corpus.txt",
  "source/darwin",
  "source/unix",
  "source/windows",
] + excludesFromAll

var calDependencies: [Target.Dependency] = [
  "AwsCCommon",
  "AwsCCal_Platform",
  .target(name: "LibCrypto", condition: .when(platforms: [.linux, .android])),
]

packageTargets.append(
  .systemLibrary(
    name: "LibCrypto",
    pkgConfig: "libcrypto",
    providers: [
      .apt(["openssl libssl-dev"]),
      .yum(["openssl openssl-devel"]),
    ]
  )
)

//////////////////////////////////////////////////////////////////////
// MARK: - s2n-tls
//////////////////////////////////////////////////////////////////////
let s2nExcludes = [
  "bin", "codebuild", "coverage",
  "docs", "lib", "scram", "nix", "compliance",
  "s2n.mk", "stuffer/Makefile", "crypto/Makefile",
  "utils/Makefile", "error/Makefile",
  "scripts", "bindings", "VERSIONING.rst", "tests",
  "cmake/s2n-config.cmake", "CMakeLists.txt", "README.md", "cmake", "NOTICE", "LICENSE",
  "flake.lock", "flake.nix",
]
packageTargets.append(
  .target(
    name: "S2N_TLS",
    dependencies: ["LibCrypto"],
    path: "aws-common-runtime/s2n",
    exclude: s2nExcludes,
    publicHeadersPath: "api",
    cSettings: [
      .headerSearchPath("./"),
      .define("S2N_NO_PQ"),
      .define("_S2N_PRELUDE_INCLUDED"),
      .define("S2N_BUILD_RELEASE"),
      .define("_FORTIFY_SOURCE", to: "2"),
      .define("POSIX_C_SOURCE", to: "200809L"),
      .define("__ANDROID__", .when(platforms: [.android])),
    ]
  )
)

//////////////////////////////////////////////////////////////////////
// MARK: - aws-c-io
//
// Platform sources (source/darwin, source/bsd, source/linux, source/s2n,
// source/windows) are excluded from the main target and compiled via
// AwsCIo_Platform wrapper target using preprocessor guards.
// source/posix is kept in the main target (used on macOS, Linux, and Android).
//////////////////////////////////////////////////////////////////////
let awsCIoPlatformExcludes = [
  "docs", "CODE_OF_CONDUCT.md", "codebuild", "PKCS11.md",
  "source/pkcs11/v2.40",
  "source/darwin",
  "source/bsd",
  "source/linux",
  "source/s2n",
  "source/windows",
] + excludesFromAll

var cSettingsIO: [CSetting] = cSettings + [
  .define("AWS_ENABLE_DISPATCH_QUEUE", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS])),
  .define("AWS_ENABLE_KQUEUE", .when(platforms: [.macOS])),
  .define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS])),
  .define("AWS_ENABLE_EPOLL", .when(platforms: [.linux, .android])),
  .define("USE_S2N", .when(platforms: [.linux, .android])),
]

var ioDependencies: [Target.Dependency] = [
  "AwsCCommon",
  "AwsCCal",
  "AwsCIo_Platform",
  .target(name: "S2N_TLS", condition: .when(platforms: [.linux, .android])),
]

swiftTestSettings.append(.define("AWS_ENABLE_DISPATCH_QUEUE"))
swiftTestSettings.append(.define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS])))
swiftTestSettings.append(.define("AWS_ENABLE_KQUEUE", .when(platforms: [.macOS])))

//////////////////////////////////////////////////////////////////////
// MARK: - aws-c-checksums
//////////////////////////////////////////////////////////////////////
var awsCChecksumsExcludes = [
  "bin",
  "CMakeLists.txt",
  "LICENSE",
  "builder.json",
  "README.md",
  "cmake",
  "tests",
]

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
var awsCCompressionPlatformExcludes =
  [
    "source/huffman_generator/", "CODE_OF_CONDUCT.md",
    "codebuild",
  ] + excludesFromAll

//////////////////////////////////////////////////////////////////////
/// aws-c-http
//////////////////////////////////////////////////////////////////////
var awsCHttpPlatformExcludes =
  [
    "bin",
    "integration-testing",
    "include/aws/http/private",
    "CODE_OF_CONDUCT.md",
    "codebuild/linux-integration-tests.yml",
  ] + excludesFromAll

//////////////////////////////////////////////////////////////////////
/// aws-c-auth
//////////////////////////////////////////////////////////////////////
let awsCAuthPlatformExcludes = ["CODE_OF_CONDUCT.md"] + excludesFromAll

//////////////////////////////////////////////////////////////////////
/// aws-c-eventstreams
//////////////////////////////////////////////////////////////////////
let awsCEventStreamExcludes =
  [
    "bin",
    "CODE_OF_CONDUCT.md",
    "clang-tidy/run-clang-tidy.sh",
  ] + excludesFromAll

//////////////////////////////////////////////////////////////////////
/// aws-c-mqtt
//////////////////////////////////////////////////////////////////////

let awsCMqttExcludes =
  [
    "bin",
    "CODE_OF_CONDUCT.md",
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
    dependencies: [
        "AwsCPlatformConfig",
        "AwsCCommon_Platform",
    ],
    path: "aws-common-runtime/aws-c-common",
    exclude: awsCCommonPlatformExcludes,
    cSettings: cSettingsCommon
  ),
  .target(
    name: "AwsCCommon_Platform",
    dependencies: ["AwsCPlatformConfig"],
    path: "aws-common-runtime/aws-c-common-platform",
    publicHeadersPath: "include",
    cSettings: [
      .headerSearchPath("../aws-c-common/include"),
      .define("DEBUG_BUILD", .when(configuration: .debug)),
      .define("__ANDROID__", .when(platforms: [.android])),
    ]
  ),
  .target(
    name: "AwsCCal_Platform",
    dependencies: [
      "AwsCCommon",
      .target(name: "LibCrypto", condition: .when(platforms: [.linux, .android])),
    ],
    path: "aws-common-runtime/aws-c-cal-platform",
    publicHeadersPath: "include",
    cSettings: [
      .headerSearchPath("../aws-c-cal/include"),
      .define("DEBUG_BUILD", .when(configuration: .debug)),
      .define("INTEL_NO_ITTNOTIFY_API"),
      .define("AWS_APPSTORE_SAFE"),
      .define("__ANDROID__", .when(platforms: [.android])),
    ]
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
    name: "AwsCIo_Platform",
    dependencies: [
      "AwsCCommon",
      "AwsCCal",
      .target(name: "S2N_TLS", condition: .when(platforms: [.linux, .android])),
    ],
    path: "aws-common-runtime/aws-c-io-platform",
    publicHeadersPath: "include",
    cSettings: [
      .headerSearchPath("../aws-c-io/include"),
      .headerSearchPath("../s2n/api"),
      .define("DEBUG_BUILD", .when(configuration: .debug)),
      .define("INTEL_NO_ITTNOTIFY_API"),
      .define("AWS_APPSTORE_SAFE"),
      .define("AWS_ENABLE_DISPATCH_QUEUE", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS])),
      .define("AWS_ENABLE_KQUEUE", .when(platforms: [.macOS])),
      .define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS])),
      .define("AWS_ENABLE_EPOLL", .when(platforms: [.linux, .android])),
      .define("USE_S2N", .when(platforms: [.linux, .android])),
      .define("__ANDROID__", .when(platforms: [.android])),
    ]
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
    dependencies: [
      "AwsCHttp", "AwsCCompression", "AwsCCal", "AwsCIo", "AwsCSdkUtils", "AwsCCommon",
    ],
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
    dependencies: [
      "AwsCAuth",
      "AwsCHttp",
      "AwsCCal",
      "AwsCCompression",
      "AwsCIo",
      "AwsCCommon",
      "AwsCChecksums",
      "AwsCEventStream",
      "AwsCMqtt",
      "LibNative",
    ],
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
])
package.targets = packageTargets
