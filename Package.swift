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
]

//////////////////////////////////////////////////////////////////////
/// aws-lc (bundled libcrypto for macOS and Linux)
//////////////////////////////////////////////////////////////////////
#if os(Linux) || os(macOS)

var awsLcExcludes: [String] = [
  // .cc test files scattered in crypto/ subdirectories
  "crypto/abi_self_test.cc",
  "crypto/asn1/asn1_test.cc",
  "crypto/base64/base64_test.cc",
  "crypto/bio/bio_md_test.cc",
  "crypto/bio/bio_socket_test.cc",
  "crypto/bio/bio_test.cc",
  "crypto/blake2/blake2_test.cc",
  "crypto/buf/buf_test.cc",
  "crypto/bytestring/bytestring_test.cc",
  "crypto/chacha/chacha_test.cc",
  "crypto/cipher_extra/aead_test.cc",
  "crypto/cipher_extra/cipher_test.cc",
  "crypto/compiler_test.cc",
  "crypto/conf/conf_test.cc",
  "crypto/console/console_test.cc",
  "crypto/constant_time_test.cc",
  "crypto/crypto_test.cc",
  "crypto/des/des_test.cc",
  "crypto/dh_extra/dh_test.cc",
  "crypto/digest_extra/digest_test.cc",
  "crypto/dsa/dsa_test.cc",
  "crypto/ecdh_extra/ecdh_test.cc",
  "crypto/endian_test.cc",
  "crypto/err/err_test.cc",
  "crypto/evp_extra/evp_extra_test.cc",
  "crypto/evp_extra/evp_test.cc",
  "crypto/evp_extra/mldsa_test.cc",
  "crypto/evp_extra/p_kem_test.cc",
  "crypto/evp_extra/p_pqdsa_test.cc",
  "crypto/evp_extra/scrypt_test.cc",
  "crypto/fips_callback_test.cc",
  "crypto/hmac_extra/hmac_test.cc",
  "crypto/hpke/hpke_test.cc",
  "crypto/hrss/hrss_test.cc",
  "crypto/impl_dispatch_test.cc",
  "crypto/lhash/lhash_test.cc",
  "crypto/mem_set_test.cc",
  "crypto/mem_test.cc",
  "crypto/obj/obj_test.cc",
  "crypto/ocsp/ocsp_integration_test.cc",
  "crypto/ocsp/ocsp_test.cc",
  "crypto/pem/pem_test.cc",
  "crypto/pkcs7/pkcs7_test.cc",
  "crypto/pkcs8/pkcs12_test.cc",
  "crypto/pkcs8/pkcs8_test.cc",
  "crypto/poly1305/poly1305_test.cc",
  "crypto/pool/pool_test.cc",
  "crypto/rand_extra/ccrandomgeneratebytes_test.cc",
  "crypto/rand_extra/getentropy_test.cc",
  "crypto/rand_extra/urandom_test.cc",
  "crypto/rand_extra/vm_ube_fallback_test.cc",
  "crypto/refcount_test.cc",
  "crypto/rsa_extra/rsa_test.cc",
  "crypto/rsa_extra/rsassa_pss_asn1_test.cc",
  "crypto/rwlock_static_init.cc",
  "crypto/self_test.cc",
  "crypto/siphash/siphash_test.cc",
  "crypto/spake25519/spake25519_test.cc",
  "crypto/stack/stack_test.cc",
  "crypto/thread_test.cc",
  "crypto/trust_token/trust_token_test.cc",
  "crypto/ube/fork_ube_detect_test.cc",
  "crypto/ube/ube_test.cc",
  "crypto/ube/vm_ube_detect_test.cc",
  "crypto/x509/tab_test.cc",
  "crypto/x509/x509_compat_test.cc",
  "crypto/x509/x509_test.cc",
  "crypto/x509/x509_time_test.cc",
  // Test .c file and test data directories/files within crypto subdirs
  "crypto/dynamic_loading_test.c",
  "crypto/cipher_extra/test/",
  "crypto/ocsp/test/",
  "crypto/pkcs8/test/",
  "crypto/x509/test/",
  "crypto/blake2/blake2b256_tests.txt",
  "crypto/ecdh_extra/ecdh_tests.txt",
  "crypto/evp_extra/evp_tests.txt",
  "crypto/evp_extra/kbkdf_expand_tests.txt",
  "crypto/evp_extra/mldsa_corrupted_key_tests.txt",
  "crypto/evp_extra/scrypt_tests.txt",
  "crypto/evp_extra/sshkdf_tests.txt",
  "crypto/hmac_extra/hmac_tests.txt",
  "crypto/hpke/hpke_test_vectors.txt",
  "crypto/hpke/test-vectors.json",
  "crypto/poly1305/poly1305_tests.txt",
  "crypto/siphash/siphash_tests.txt",
  "crypto/obj/objects.txt",
  "crypto/obj/README",
  "crypto/obj/obj_mac.num",
  "crypto/obj/objects.go",
  // Perlasm scripts (not compiled)
  "crypto/chacha/asm/",
  "crypto/cipher_extra/asm/",
  // Error data generation files and .errordata
  "crypto/err/err_data_generate.go",
  "crypto/err/asn1.errordata",
  "crypto/err/bio.errordata",
  "crypto/err/bn.errordata",
  "crypto/err/cipher.errordata",
  "crypto/err/conf.errordata",
  "crypto/err/dh.errordata",
  "crypto/err/digest.errordata",
  "crypto/err/dsa.errordata",
  "crypto/err/ec.errordata",
  "crypto/err/ecdh.errordata",
  "crypto/err/ecdsa.errordata",
  "crypto/err/engine.errordata",
  "crypto/err/evp.errordata",
  "crypto/err/hkdf.errordata",
  "crypto/err/hmac.errordata",
  "crypto/err/obj.errordata",
  "crypto/err/ocsp.errordata",
  "crypto/err/pem.errordata",
  "crypto/err/pkcs7.errordata",
  "crypto/err/pkcs8.errordata",
  "crypto/err/rsa.errordata",
  "crypto/err/ssl.errordata",
  "crypto/err/trust_token.errordata",
  "crypto/err/x509.errordata",
  "crypto/err/x509v3.errordata",
  // Other non-source files
  "crypto/ecdh_extra/make_secp256k1_test_vectors.go",
  "crypto/hpke/translate_test_vectors.py",
  // Deeply nested .cc test files
  "crypto/pkcs7/bio/bio_cipher_test.cc",
  "crypto/decrepit/blowfish/blowfish_test.cc",
  "crypto/decrepit/cast/cast_test.cc",
  "crypto/decrepit/evp/evp_test.cc",
  "crypto/decrepit/cfb/cfb_test.cc",
  "crypto/decrepit/ripemd/ripemd_test.cc",
  // Network socket files (not needed)
  "crypto/bio/connect.c",
  "crypto/bio/socket.c",
  "crypto/bio/socket_helper.c",
  "crypto/bio/dgram.c",
  // Windows-only files
  "crypto/refcount_win.c",
  "crypto/thread_win.c",
  "crypto/thread_none.c",
  // Test trampolines in generated assembly
  "generated-src/linux-x86_64/crypto/test/",
  "generated-src/linux-aarch64/crypto/test/",
  "generated-src/mac-x86_64/crypto/test/",
  "generated-src/ios-aarch64/crypto/test/",
  // s2n-bignum non-source files within included subdirs
  "third_party/s2n-bignum/s2n-bignum-imported/arm/p256/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/p256/unopt/",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/p384/unopt/",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/p521/unopt/",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/fastmul/unopt/",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/p384/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/p521/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/curve25519/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/sha3/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/fastmul/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/arm/generic/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p256/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p384/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p521/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/x86_att/curve25519/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/x86_att/sha3/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/x86_att/fastmul/Makefile",
  "third_party/s2n-bignum/s2n-bignum-imported/x86_att/generic/Makefile",
]

// Exclude wrong architecture assembly (no preprocessor guards)
#if arch(arm64)
  awsLcExcludes.append(contentsOf: [
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p256/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p384/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p521/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/curve25519/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/sha3/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/fastmul/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/generic/",
  ])
#elseif arch(x86_64)
  awsLcExcludes.append(contentsOf: [
    "third_party/s2n-bignum/s2n-bignum-imported/arm/p256/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/p384/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/p521/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/curve25519/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/sha3/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/fastmul/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/generic/",
    // aarch64-only assembly
    "third_party/s2n-bignum/s2n-bignum-to-be-imported/arm/aes/",
    "crypto/fipsmodule/ml_kem/mlkem/native/aarch64/src/",
  ])
#else
  awsLcExcludes.append(contentsOf: [
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p256/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p384/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p521/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/curve25519/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/sha3/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/fastmul/",
    "third_party/s2n-bignum/s2n-bignum-imported/x86_att/generic/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/p256/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/p384/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/p521/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/curve25519/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/sha3/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/fastmul/",
    "third_party/s2n-bignum/s2n-bignum-imported/arm/generic/",
    "third_party/s2n-bignum/s2n-bignum-to-be-imported/arm/aes/",
    "crypto/fipsmodule/ml_kem/mlkem/native/aarch64/src/",
  ])
#endif

packageTargets.append(
  .target(
    name: "AwsLc",
    path: "aws-common-runtime/aws-lc",
    exclude: awsLcExcludes,
    sources: [
      // Outer crypto sources
      "crypto/asn1/",
      "crypto/base64/",
      "crypto/bio/",
      "crypto/blake2/",
      "crypto/bn_extra/",
      "crypto/buf/",
      "crypto/bytestring/",
      "crypto/chacha/",
      "crypto/cipher_extra/",
      "crypto/conf/",
      "crypto/console/",
      "crypto/crypto.c",
      "crypto/des/",
      "crypto/dh_extra/",
      "crypto/digest_extra/",
      "crypto/dsa/",
      "crypto/ec_extra/",
      "crypto/ecdh_extra/",
      "crypto/ecdsa_extra/",
      "crypto/engine/",
      "crypto/err/",
      "crypto/evp_extra/",
      "crypto/ex_data.c",
      "crypto/hpke/",
      "crypto/hrss/",
      "crypto/lhash/",
      "crypto/md4/",
      "crypto/mem.c",
      "crypto/obj/",
      "crypto/ocsp/",
      "crypto/pem/",
      "crypto/pkcs7/",
      "crypto/pkcs8/",
      "crypto/poly1305/",
      "crypto/pool/",
      "crypto/rand_extra/",
      "crypto/rc4/",
      "crypto/refcount_c11.c",
      "crypto/refcount_lock.c",
      "crypto/rsa_extra/",
      "crypto/siphash/",
      "crypto/spake25519/",
      "crypto/stack/",
      "crypto/thread.c",
      "crypto/thread_pthread.c",
      "crypto/trust_token/",
      "crypto/ube/",
      "crypto/ui/",
      "crypto/x509/",
      "crypto/decrepit/",
      // fipsmodule (unity build)
      "crypto/fipsmodule/bcm.c",
      "crypto/fipsmodule/fips_shared_support.c",
      "crypto/fipsmodule/cpucap/cpucap.c",
      // Jitterentropy (entropy source)
      "third_party/jitterentropy/jitterentropy-library/src/",
      // Pre-generated assembly (self-selecting preprocessor guards)
      "generated-src/err_data.c",
      "generated-src/linux-x86_64/crypto/",
      "generated-src/linux-aarch64/crypto/",
      "generated-src/mac-x86_64/crypto/",
      "generated-src/ios-aarch64/crypto/",
      // AES-XTS assembly (aarch64 only)
      "third_party/s2n-bignum/s2n-bignum-to-be-imported/arm/aes/",
      // s2n-bignum assembly (wrong arch excluded above)
      "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p256/",
      "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p384/",
      "third_party/s2n-bignum/s2n-bignum-imported/x86_att/p521/",
      "third_party/s2n-bignum/s2n-bignum-imported/x86_att/curve25519/",
      "third_party/s2n-bignum/s2n-bignum-imported/x86_att/sha3/",
      "third_party/s2n-bignum/s2n-bignum-imported/x86_att/fastmul/",
      "third_party/s2n-bignum/s2n-bignum-imported/x86_att/generic/",
      "third_party/s2n-bignum/s2n-bignum-imported/arm/p256/",
      "third_party/s2n-bignum/s2n-bignum-imported/arm/p384/",
      "third_party/s2n-bignum/s2n-bignum-imported/arm/p521/",
      "third_party/s2n-bignum/s2n-bignum-imported/arm/curve25519/",
      "third_party/s2n-bignum/s2n-bignum-imported/arm/sha3/",
      "third_party/s2n-bignum/s2n-bignum-imported/arm/fastmul/",
      "third_party/s2n-bignum/s2n-bignum-imported/arm/generic/",
    ],
    publicHeadersPath: "include",
    cSettings: [
      .define("BORINGSSL_IMPLEMENTATION"),
      .define("MLK_CONFIG_NO_ASM"),
      .headerSearchPath("crypto/"),
      .headerSearchPath("crypto/fipsmodule/"),
      .headerSearchPath("crypto/fipsmodule/cpucap/"),
      .headerSearchPath("third_party/s2n-bignum/"),
      .headerSearchPath("third_party/jitterentropy/jitterentropy-library/"),
      .headerSearchPath("third_party/s2n-bignum/s2n-bignum-imported/include/"),
      .headerSearchPath("crypto/fipsmodule/ml_kem/"),
    ]
  ))

#endif

//////////////////////////////////////////////////////////////////////
/// aws-c-cal
//////////////////////////////////////////////////////////////////////
var calDependencies: [Target.Dependency] = ["AwsCCommon"]
#if os(Linux) || os(macOS)
  calDependencies.append("AwsLc")
#endif

var awsCCalPlatformExcludes =
  [
    "bin",
    "include/aws/cal/private",
    "source/shared/ed25519.c",
    "CODE_OF_CONDUCT.md",
    "ecdsa-fuzz-corpus/windows/p256_sig_corpus.txt",
    "ecdsa-fuzz-corpus/darwin/p256_sig_corpus.txt",
  ] + excludesFromAll

#if os(Windows)
  awsCCalPlatformExcludes.append("source/darwin")
  awsCCalPlatformExcludes.append("source/unix")
  awsCCalPlatformExcludes.append("source/shared/lccrypto_common.c")
#elseif os(Linux)
  awsCCalPlatformExcludes.append("source/windows")
  awsCCalPlatformExcludes.append("source/darwin")
#else  // macOS, iOS, watchOS, tvOS
  awsCCalPlatformExcludes.append("source/windows")
  awsCCalPlatformExcludes.append("source/unix")
  awsCCalPlatformExcludes.append("source/shared/lccrypto_common.c")
#endif

//////////////////////////////////////////////////////////////////////
/// s2n-tls
//////////////////////////////////////////////////////////////////////
#if os(Linux) || os(macOS)
  let s2nExcludes = [
    "bin", "codebuild", "coverage", "docker-images",
    "docs", "lib",
    "libcrypto-build", "scram",
    "s2n.mk", "Makefile", "stuffer/Makefile", "crypto/Makefile",
    "tls/Makefile", "utils/Makefile", "error/Makefile", "tls/extensions/Makefile",
    "scripts/", "codebuild", "bindings/rust", "VERSIONING.rst", "tests",
    "cmake/s2n-config.cmake", "CMakeLists.txt", "README.md", "cmake", "NOTICE", "LICENSE",
  ]
  packageTargets.append(
    .target(
      name: "S2N_TLS",
      dependencies: ["AwsLc"],
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
        // aws-lc feature defines (determined by feature probes against aws-lc headers)
        .define("S2N_LIBCRYPTO_SUPPORTS_HKDF"),
        .define("S2N_LIBCRYPTO_SUPPORTS_EVP_MD_CTX_SET_PKEY_CTX"),
        .define("S2N_LIBCRYPTO_SUPPORTS_RSA_PSS_SIGNING"),
        .define("S2N_LIBCRYPTO_SUPPORTS_EVP_MD5_SHA1_HASH"),
        .define("S2N_LIBCRYPTO_SUPPORTS_EVP_RC4"),
        .define("S2N_LIBCRYPTO_SUPPORTS_EVP_AEAD_TLS"),
        .define("S2N_LIBCRYPTO_SUPPORTS_CUSTOM_OID"),
        .define("S2N_LIBCRYPTO_SUPPORTS_FLAG_NO_CHECK_TIME"),
        .define("S2N_LIBCRYPTO_SUPPORTS_GET0_CHAIN"),
        .define("S2N_LIBCRYPTO_SUPPORTS_PRIVATE_RAND"),
        .define("S2N_LIBCRYPTO_SUPPORTS_PUBLIC_RAND"),
        .define("S2N_LIBCRYPTO_SUPPORTS_SHAKE"),
        .define("S2N_LIBCRYPTO_SUPPORTS_X509_STORE_LIST"),
        .define("S2N_LIBCRYPTO_SUPPORTS_EC_KEY_CHECK_FIPS"),
        // Compiler/OS feature probes
        .define("S2N_FALL_THROUGH_SUPPORTED"),
        .define("S2N_DIAGNOSTICS_POP_SUPPORTED"),
        .define("S2N_DIAGNOSTICS_PUSH_SUPPORTED"),
        .define("S2N_ATOMIC_SUPPORTED"),
        .define("S2N_CPUID_AVAILABLE"),
        .define("S2N_LIBCRYPTO_SANITY_PROBE"),
      ]
    ))
#endif

//////////////////////////////////////////////////////////////////////
/// aws-c-io
//////////////////////////////////////////////////////////////////////
var ioDependencies: [Target.Dependency] = ["AwsCCommon", "AwsCCal"]
var awsCIoPlatformExcludes =
  [
    "docs", "CODE_OF_CONDUCT.md", "codebuild", "PKCS11.md",
    "source/pkcs11/v2.40",
  ] + excludesFromAll
var cSettingsIO = cSettings
var cSettingsHttp = cSettings

#if os(Linux) || os(macOS)
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
#elseif os(macOS)
  awsCIoPlatformExcludes.append("source/windows")
  awsCIoPlatformExcludes.append("source/linux")
  awsCIoPlatformExcludes.append("source/darwin/dispatch_queue_event_loop.c")
  awsCIoPlatformExcludes.append("source/darwin/nw_socket.c")
  cSettingsIO.append(.define("__APPLE__"))
  cSettingsIO.append(.define("AWS_ENABLE_KQUEUE"))
  swiftTestSettings.append(.define("__APPLE__"))
  swiftTestSettings.append(.define("AWS_ENABLE_KQUEUE"))
#else  // iOS, watchOS, tvOS
  awsCIoPlatformExcludes.append("source/windows")
  awsCIoPlatformExcludes.append("source/linux")
  awsCIoPlatformExcludes.append("source/s2n")
  cSettingsIO.append(.define("__APPLE__"))
  cSettingsIO.append(.define("AWS_ENABLE_DISPATCH_QUEUE"))
  cSettingsIO.append(.define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS])))
  cSettingsHttp.append(.define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS])))
  swiftTestSettings.append(.define("__APPLE__"))
  swiftTestSettings.append(.define("AWS_ENABLE_DISPATCH_QUEUE"))
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
    cSettings: cSettingsHttp
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
