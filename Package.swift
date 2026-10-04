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
  // The NDK's CMake toolchain defines ANDROID (clang only defines __ANDROID__), and the CRT relies on it
  .define("ANDROID", .when(platforms: [.android])),
]

let applePlatforms: [Platform] = [.macOS, .iOS, .tvOS, .watchOS, .visionOS]
let linuxLikePlatforms: [Platform] = [.linux, .android]
let posixPlatforms: [Platform] = applePlatforms + linuxLikePlatforms

/// Store any defines that will be used by Swift Tests in swiftTestSettings
var swiftTestSettings: [SwiftSetting] = [
  .define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS]))
]

//////////////////////////////////////////////////////////////////////
/// Configure C targets.
/// Note: We can not use unsafe flags because SwiftPM makes the target ineligible for use by other packages.
///       We are also not using any architecture based conditionals due to lack of proper cross compilation support.
///
/// Platform selection: `#if os()` in this manifest is evaluated on the HOST, which breaks cross compilation.
/// Instead, each platform-specific source directory (e.g. aws-c-io/source/linux) is excluded from its
/// library target and built as a separate target. The library depends on that target only for the
/// platforms that need it, using `.when(platforms:)`, which is evaluated for the TARGET platform.
/// This mirrors the source selection in each library's CMakeLists.txt.
//////////////////////////////////////////////////////////////////////

/// A target that compiles one platform-specific directory under `aws-common-runtime/<library>/source/`.
func platformTarget(
  _ name: String,
  library: String,
  directory: String,
  sources: [String]? = nil,
  exclude: [String] = [],
  dependencies: [Target.Dependency],
  cSettings: [CSetting],
  linkerSettings: [LinkerSetting] = []
) -> Target {
  .target(
    name: name,
    dependencies: dependencies,
    path: "aws-common-runtime/\(library)/source/\(directory)",
    exclude: exclude,
    sources: sources,
    publicHeadersPath: ".",
    // reach the library's own (including private) headers without depending on the library target
    cSettings: cSettings + [.headerSearchPath("../../include")],
    linkerSettings: linkerSettings
  )
}

//////////////////////////////////////////////////////////////////////
/// Configure aws-c-common
//////////////////////////////////////////////////////////////////////
var awsCCommonPlatformExcludes =
  [
    "AWSCRTAndroidTestRunner", "verification",
    "include/aws/common/",
    "scripts/appverifier_ctest.py",
    "scripts/appverifier_xml.py",
    "bin/",
    // built by the platform targets below
    "source/android", "source/linux", "source/posix", "source/windows",
    "source/platform_fallback_stubs/file_direct_io.c",
  ] + excludesFromAll

// includes arch/generic because the SwiftPM doesn't like the necessary compiler flags.
awsCCommonPlatformExcludes.append("source/arch/intel")
awsCCommonPlatformExcludes.append("source/arch/arm")
let cSettingsCommonDefines: [CSetting] = [
  .define("DEBUG_BUILD", .when(configuration: .debug)),
  .define("ANDROID", .when(platforms: [.android])),
]
let cSettingsCommon: [CSetting] = cSettingsCommonDefines + [.headerSearchPath("source/external/libcbor")]

let commonPlatformDependencies: [Target.Dependency] = ["AwsCPlatformConfig"]
let commonPlatformTargets: [Target] = [
  platformTarget(
    "AwsCCommonAndroid", library: "aws-c-common", directory: "android",
    dependencies: commonPlatformDependencies, cSettings: cSettingsCommonDefines,
    // source/android/logging.c writes to logcat
    linkerSettings: [.linkedLibrary("log")]),
  platformTarget(
    "AwsCCommonLinux", library: "aws-c-common", directory: "linux",
    // the platform fallback stub is used for system_info.c on every platform
    exclude: ["system_info.c"],
    dependencies: commonPlatformDependencies, cSettings: cSettingsCommonDefines),
  platformTarget(
    "AwsCCommonPosix", library: "aws-c-common", directory: "posix",
    dependencies: commonPlatformDependencies, cSettings: cSettingsCommonDefines),
  platformTarget(
    "AwsCCommonWindows", library: "aws-c-common", directory: "windows",
    dependencies: commonPlatformDependencies, cSettings: cSettingsCommonDefines),
  platformTarget(
    "AwsCCommonFileIOStub", library: "aws-c-common", directory: "platform_fallback_stubs",
    sources: ["file_direct_io.c"],
    dependencies: commonPlatformDependencies, cSettings: cSettingsCommonDefines),
]
let commonDependencies: [Target.Dependency] = [
  "AwsCPlatformConfig",
  .target(name: "AwsCCommonAndroid", condition: .when(platforms: [.android])),
  .target(name: "AwsCCommonLinux", condition: .when(platforms: [.linux])),
  .target(name: "AwsCCommonPosix", condition: .when(platforms: posixPlatforms)),
  .target(name: "AwsCCommonWindows", condition: .when(platforms: [.windows])),
  .target(name: "AwsCCommonFileIOStub", condition: .when(platforms: applePlatforms + [.android, .windows])),
]

//////////////////////////////////////////////////////////////////////
// MARK: - aws-lc (libcrypto)
//
// Built from source for Android, which has no system libcrypto.
// On Apple platforms, native Security.framework / CommonCrypto are used
// by aws-c-cal and aws-c-io, so this target is conditionally linked.
//
// Uses OPENSSL_NO_ASM for portability (pure C fallbacks).
// Uses DISABLE_CPU_JITTER_ENTROPY (OS entropy is sufficient for non-FIPS).
//////////////////////////////////////////////////////////////////////
// Explicit source file list for aws-lc's libcrypto.
// Directory-based auto-discovery is impractical here because aws-lc has
// test data files (.pem, .txt, .errordata, .p12) deeply embedded alongside
// source files in 15+ directories, and SwiftPM tries to compile them all.
let awsLCSources: [String] = [
  // crypto/ sources (from crypto/CMakeLists.txt crypto_objects)
  "crypto/asn1/a_bitstr.c", "crypto/asn1/a_bool.c", "crypto/asn1/a_d2i_fp.c",
  "crypto/asn1/a_dup.c", "crypto/asn1/a_gentm.c", "crypto/asn1/a_i2d_fp.c",
  "crypto/asn1/a_int.c", "crypto/asn1/a_mbstr.c", "crypto/asn1/a_object.c",
  "crypto/asn1/a_octet.c", "crypto/asn1/a_strex.c", "crypto/asn1/a_strnid.c",
  "crypto/asn1/a_time.c", "crypto/asn1/a_type.c", "crypto/asn1/a_utctm.c",
  "crypto/asn1/a_utf8.c", "crypto/asn1/asn1_lib.c", "crypto/asn1/asn1_par.c",
  "crypto/asn1/asn_pack.c", "crypto/asn1/f_int.c", "crypto/asn1/f_string.c",
  "crypto/asn1/tasn_dec.c", "crypto/asn1/tasn_enc.c", "crypto/asn1/tasn_fre.c",
  "crypto/asn1/tasn_new.c", "crypto/asn1/tasn_typ.c", "crypto/asn1/tasn_utl.c",
  "crypto/asn1/posix_time.c",
  "crypto/base64/base64.c",
  "crypto/bio/bio.c", "crypto/bio/bio_addr.c", "crypto/bio/bio_mem.c",
  "crypto/bio/connect.c", "crypto/bio/dgram.c", "crypto/bio/errno.c",
  "crypto/bio/fd.c", "crypto/bio/file.c", "crypto/bio/hexdump.c",
  "crypto/bio/md.c", "crypto/bio/pair.c", "crypto/bio/printf.c",
  "crypto/bio/socket.c", "crypto/bio/socket_helper.c",
  "crypto/blake2/blake2.c",
  "crypto/bn_extra/bn_asn1.c", "crypto/bn_extra/convert.c",
  "crypto/buf/buf.c",
  "crypto/bytestring/asn1_compat.c", "crypto/bytestring/ber.c",
  "crypto/bytestring/cbb.c", "crypto/bytestring/cbs.c",
  "crypto/bytestring/unicode.c",
  "crypto/chacha/chacha.c",
  "crypto/cipher_extra/cipher_extra.c", "crypto/cipher_extra/derive_key.c",
  "crypto/cipher_extra/e_aesctrhmac.c", "crypto/cipher_extra/e_aesgcmsiv.c",
  "crypto/cipher_extra/e_chacha20poly1305.c",
  "crypto/cipher_extra/e_aes_cbc_hmac_sha1.c",
  "crypto/cipher_extra/e_aes_cbc_hmac_sha256.c",
  "crypto/cipher_extra/e_des.c", "crypto/cipher_extra/e_null.c",
  "crypto/cipher_extra/e_rc2.c", "crypto/cipher_extra/e_rc4.c",
  "crypto/cipher_extra/e_tls.c", "crypto/cipher_extra/tls_cbc.c",
  "crypto/conf/conf.c",
  "crypto/console/console.c",
  "crypto/crypto.c",
  "crypto/des/des.c",
  "crypto/dh_extra/params.c", "crypto/dh_extra/dh_asn1.c",
  "crypto/digest_extra/digest_extra.c",
  "crypto/dsa/dsa.c", "crypto/dsa/dsa_asn1.c",
  "crypto/ecdh_extra/ecdh_extra.c",
  "crypto/ecdsa_extra/ecdsa_asn1.c",
  "crypto/ec_extra/ec_asn1.c", "crypto/ec_extra/ec_derive.c",
  "crypto/ec_extra/hash_to_curve.c",
  "crypto/err/err.c",
  "crypto/engine/engine.c",
  "crypto/evp_extra/evp_asn1.c", "crypto/evp_extra/p_dh.c",
  "crypto/evp_extra/p_dh_asn1.c", "crypto/evp_extra/p_dsa.c",
  "crypto/evp_extra/p_dsa_asn1.c", "crypto/evp_extra/p_ec_asn1.c",
  "crypto/evp_extra/p_ed25519_asn1.c", "crypto/evp_extra/p_hmac_asn1.c",
  "crypto/evp_extra/p_kem_asn1.c", "crypto/evp_extra/p_pqdsa_asn1.c",
  "crypto/evp_extra/p_rsa_asn1.c", "crypto/evp_extra/p_x25519.c",
  "crypto/evp_extra/p_x25519_asn1.c", "crypto/evp_extra/p_methods.c",
  "crypto/evp_extra/print.c", "crypto/evp_extra/scrypt.c",
  "crypto/evp_extra/sign.c",
  "crypto/ex_data.c",
  "crypto/hpke/hpke.c",
  "crypto/hrss/hrss.c",
  "crypto/lhash/lhash.c",
  "crypto/md4/md4.c",
  "crypto/mem.c",
  "crypto/obj/obj.c", "crypto/obj/obj_xref.c",
  "crypto/ocsp/ocsp_asn.c", "crypto/ocsp/ocsp_client.c",
  "crypto/ocsp/ocsp_extension.c", "crypto/ocsp/ocsp_http.c",
  "crypto/ocsp/ocsp_lib.c", "crypto/ocsp/ocsp_print.c",
  "crypto/ocsp/ocsp_server.c", "crypto/ocsp/ocsp_verify.c",
  "crypto/pem/pem_all.c", "crypto/pem/pem_info.c", "crypto/pem/pem_lib.c",
  "crypto/pem/pem_oth.c", "crypto/pem/pem_pk8.c", "crypto/pem/pem_pkey.c",
  "crypto/pem/pem_x509.c", "crypto/pem/pem_xaux.c",
  "crypto/pkcs7/bio/cipher.c", "crypto/pkcs7/pkcs7.c",
  "crypto/pkcs7/pkcs7_asn1.c", "crypto/pkcs7/pkcs7_x509.c",
  "crypto/pkcs8/pkcs8.c", "crypto/pkcs8/pkcs8_x509.c",
  "crypto/pkcs8/p5_pbev2.c",
  "crypto/poly1305/poly1305.c", "crypto/poly1305/poly1305_arm.c",
  "crypto/poly1305/poly1305_vec.c",
  "crypto/pool/pool.c",
  "crypto/rand_extra/ccrandomgeneratebytes.c",
  "crypto/rand_extra/deterministic.c", "crypto/rand_extra/getentropy.c",
  "crypto/rand_extra/rand_extra.c", "crypto/rand_extra/vm_ube_fallback.c",
  "crypto/rand_extra/urandom.c", "crypto/rand_extra/windows.c",
  "crypto/rc4/rc4.c",
  "crypto/refcount_c11.c", "crypto/refcount_lock.c", "crypto/refcount_win.c",
  "crypto/rsa_extra/rsa_asn1.c", "crypto/rsa_extra/rsassa_pss_asn1.c",
  "crypto/rsa_extra/rsa_crypt.c", "crypto/rsa_extra/rsa_print.c",
  "crypto/stack/stack.c",
  "crypto/siphash/siphash.c",
  "crypto/spake25519/spake25519.c",
  "crypto/thread.c", "crypto/thread_none.c",
  "crypto/thread_pthread.c", "crypto/thread_win.c",
  "crypto/trust_token/pmbtoken.c", "crypto/trust_token/trust_token.c",
  "crypto/trust_token/voprf.c",
  "crypto/ube/ube.c", "crypto/ube/fork_ube_detect.c",
  "crypto/ube/vm_ube_detect.c",
  "crypto/x509/a_digest.c", "crypto/x509/a_sign.c", "crypto/x509/a_verify.c",
  "crypto/x509/algorithm.c", "crypto/x509/asn1_gen.c",
  "crypto/x509/by_dir.c", "crypto/x509/by_file.c", "crypto/x509/i2d_pr.c",
  "crypto/x509/name_print.c", "crypto/x509/policy.c",
  "crypto/x509/rsa_pss.c", "crypto/x509/t_crl.c", "crypto/x509/t_req.c",
  "crypto/x509/t_x509.c", "crypto/x509/t_x509a.c",
  "crypto/x509/v3_akey.c", "crypto/x509/v3_akeya.c", "crypto/x509/v3_alt.c",
  "crypto/x509/v3_bcons.c", "crypto/x509/v3_bitst.c",
  "crypto/x509/v3_conf.c", "crypto/x509/v3_cpols.c",
  "crypto/x509/v3_crld.c", "crypto/x509/v3_enum.c",
  "crypto/x509/v3_extku.c", "crypto/x509/v3_genn.c",
  "crypto/x509/v3_ia5.c", "crypto/x509/v3_info.c", "crypto/x509/v3_int.c",
  "crypto/x509/v3_lib.c", "crypto/x509/v3_ncons.c", "crypto/x509/v3_ocsp.c",
  "crypto/x509/v3_pcons.c", "crypto/x509/v3_pmaps.c",
  "crypto/x509/v3_prn.c", "crypto/x509/v3_purp.c", "crypto/x509/v3_skey.c",
  "crypto/x509/v3_utl.c",
  "crypto/x509/x_algor.c", "crypto/x509/x_all.c", "crypto/x509/x_attrib.c",
  "crypto/x509/x_crl.c", "crypto/x509/x_exten.c", "crypto/x509/x_name.c",
  "crypto/x509/x_pubkey.c", "crypto/x509/x_req.c", "crypto/x509/x_sig.c",
  "crypto/x509/x_spki.c", "crypto/x509/x_val.c", "crypto/x509/x_x509.c",
  "crypto/x509/x_x509a.c", "crypto/x509/x509_att.c",
  "crypto/x509/x509_cmp.c", "crypto/x509/x509_d2.c",
  "crypto/x509/x509_def.c", "crypto/x509/x509_ext.c",
  "crypto/x509/x509_lu.c", "crypto/x509/x509_obj.c",
  "crypto/x509/x509_req.c", "crypto/x509/x509_set.c",
  "crypto/x509/x509_trs.c", "crypto/x509/x509_txt.c",
  "crypto/x509/x509_v3.c", "crypto/x509/x509_vfy.c",
  "crypto/x509/x509_vpm.c", "crypto/x509/x509.c", "crypto/x509/x509cset.c",
  "crypto/x509/x509name.c", "crypto/x509/x509rset.c",
  "crypto/x509/x509spki.c",
  "crypto/ui/ui.c",
  "crypto/decrepit/bio/base64_bio.c", "crypto/decrepit/blowfish/blowfish.c",
  "crypto/decrepit/cast/cast.c", "crypto/decrepit/cast/cast_tables.c",
  "crypto/decrepit/cfb/cfb.c", "crypto/decrepit/dh/dh_decrepit.c",
  "crypto/decrepit/evp/evp_do_all.c", "crypto/decrepit/obj/obj_decrepit.c",
  "crypto/decrepit/ripemd/ripemd.c", "crypto/decrepit/rsa/rsa_decrepit.c",
  "crypto/decrepit/x509/x509_decrepit.c",

  // Pre-generated err_data.c (replaces CMake-generated version)
  "generated-src/err_data.c",

  // fipsmodule: compiled via bcm.c unity build (individual files rely on
  // headers included by bcm.c and cannot compile independently)
  "crypto/fipsmodule/bcm.c",
  "crypto/fipsmodule/fips_shared_support.c",
  "crypto/fipsmodule/cpucap/cpucap.c",
]
packageTargets.append(
  .target(
    name: "AwsLC",
    path: "aws-common-runtime/aws-lc",
    sources: awsLCSources,
    publicHeadersPath: "include",
    cSettings: [
      .define("BORINGSSL_IMPLEMENTATION"),
      .define("OPENSSL_NO_ASM"),
      .define("DISABLE_CPU_JITTER_ENTROPY"),
      .headerSearchPath("crypto/fipsmodule/cpucap"),
      .headerSearchPath("crypto/fipsmodule"),
      .headerSearchPath("third_party/s2n-bignum/s2n-bignum-imported/include"),
    ]
  ))

//////////////////////////////////////////////////////////////////////
/// aws-c-cal
//////////////////////////////////////////////////////////////////////
packageTargets.append(
  .systemLibrary(
    name: "LibCrypto",
    pkgConfig: "libcrypto",
    providers: [
      .apt(["openssl libssl-dev"]),
      .yum(["openssl openssl-devel"]),
    ]
  ))
// libcrypto: the system OpenSSL on Linux, the vendored aws-lc on Android. Apple and Windows use native crypto.
let libCryptoDependencies: [Target.Dependency] = [
  .target(name: "LibCrypto", condition: .when(platforms: [.linux])),
  .target(name: "AwsLC", condition: .when(platforms: [.android])),
]
let awsCCalPlatformExcludes =
  [
    "bin",
    "include/aws/cal/private",
    "source/shared/ed25519.c",
    "CODE_OF_CONDUCT.md",
    "ecdsa-fuzz-corpus/windows/p256_sig_corpus.txt",
    "ecdsa-fuzz-corpus/darwin/p256_sig_corpus.txt",
    // built by the platform targets below
    "source/darwin", "source/unix", "source/windows",
    "source/shared/lccrypto_common.c",
  ] + excludesFromAll

let calPlatformTargets: [Target] = [
  platformTarget(
    "AwsCCalDarwin", library: "aws-c-cal", directory: "darwin",
    dependencies: ["AwsCCommon"], cSettings: cSettings),
  platformTarget(
    "AwsCCalUnix", library: "aws-c-cal", directory: "unix",
    dependencies: ["AwsCCommon"] + libCryptoDependencies, cSettings: cSettings),
  platformTarget(
    "AwsCCalWindows", library: "aws-c-cal", directory: "windows",
    dependencies: ["AwsCCommon"], cSettings: cSettings),
  platformTarget(
    "AwsCCalLibCryptoCommon", library: "aws-c-cal", directory: "shared",
    sources: ["lccrypto_common.c"],
    dependencies: ["AwsCCommon"] + libCryptoDependencies, cSettings: cSettings),
]
let calDependencies: [Target.Dependency] =
  ["AwsCCommon"] + libCryptoDependencies + [
    .target(name: "AwsCCalDarwin", condition: .when(platforms: applePlatforms)),
    .target(name: "AwsCCalUnix", condition: .when(platforms: linuxLikePlatforms)),
    .target(name: "AwsCCalWindows", condition: .when(platforms: [.windows])),
    .target(name: "AwsCCalLibCryptoCommon", condition: .when(platforms: linuxLikePlatforms)),
  ]

//////////////////////////////////////////////////////////////////////
/// s2n-tls
//////////////////////////////////////////////////////////////////////
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
    dependencies: libCryptoDependencies,
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
      .define("S2N_MIN(a, b)", to: "(((a) < (b)) ? (a) : (b))"),
      .define("S2N_MAX(a, b)", to: "(((a) > (b)) ? (a) : (b))"),
    ]
  ))

//////////////////////////////////////////////////////////////////////
/// aws-c-io
//////////////////////////////////////////////////////////////////////
let awsCIoPlatformExcludes =
  [
    "docs", "CODE_OF_CONDUCT.md", "codebuild", "PKCS11.md",
    "source/pkcs11/v2.40",
    // built by the platform targets below
    "source/bsd", "source/darwin", "source/linux", "source/posix", "source/s2n", "source/windows",
  ] + excludesFromAll
let cSettingsIO: [CSetting] =
  cSettings + [
    .define("USE_S2N", .when(platforms: linuxLikePlatforms)),
    .define("AWS_ENABLE_EPOLL", .when(platforms: linuxLikePlatforms)),
    .define("AWS_ENABLE_IO_COMPLETION_PORTS", .when(platforms: [.windows])),
    .define("AWS_ENABLE_DISPATCH_QUEUE", .when(platforms: applePlatforms)),
    .define("AWS_ENABLE_KQUEUE", .when(platforms: [.macOS])),
    .define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS])),
  ]

let ioPlatformDependencies: [Target.Dependency] = ["AwsCCommon", "AwsCCal"]
let ioPlatformTargets: [Target] = [
  platformTarget(
    "AwsCIoBsd", library: "aws-c-io", directory: "bsd",
    dependencies: ioPlatformDependencies, cSettings: cSettingsIO),
  platformTarget(
    "AwsCIoDarwin", library: "aws-c-io", directory: "darwin",
    dependencies: ioPlatformDependencies, cSettings: cSettingsIO),
  platformTarget(
    "AwsCIoLinux", library: "aws-c-io", directory: "linux",
    dependencies: ioPlatformDependencies, cSettings: cSettingsIO),
  platformTarget(
    "AwsCIoPosix", library: "aws-c-io", directory: "posix",
    dependencies: ioPlatformDependencies, cSettings: cSettingsIO),
  platformTarget(
    "AwsCIoS2N", library: "aws-c-io", directory: "s2n",
    // conditional here too: SwiftPM builds a target reached through any unconditional edge,
    // even when the target holding that edge is itself skipped for the platform
    dependencies: ioPlatformDependencies + [.target(name: "S2N_TLS", condition: .when(platforms: linuxLikePlatforms))],
    cSettings: cSettingsIO),
  platformTarget(
    "AwsCIoWindows", library: "aws-c-io", directory: "windows",
    dependencies: ioPlatformDependencies, cSettings: cSettingsIO),
]
let ioDependencies: [Target.Dependency] = [
  "AwsCCommon", "AwsCCal",
  .target(name: "AwsCIoBsd", condition: .when(platforms: applePlatforms)),
  .target(name: "AwsCIoDarwin", condition: .when(platforms: applePlatforms)),
  .target(name: "AwsCIoLinux", condition: .when(platforms: linuxLikePlatforms)),
  .target(name: "AwsCIoPosix", condition: .when(platforms: posixPlatforms)),
  .target(name: "AwsCIoS2N", condition: .when(platforms: linuxLikePlatforms)),
  .target(name: "AwsCIoWindows", condition: .when(platforms: [.windows])),
]
// Http proxy is not supported with AWS_USE_SECITEM. Currently, we only support Apple Network Framework
// on iOS, and tvOS.
let cSettingsHttp: [CSetting] = cSettings + [.define("AWS_USE_SECITEM", .when(platforms: [.iOS, .tvOS]))]

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
    dependencies: commonDependencies,
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
packageTargets.append(contentsOf: commonPlatformTargets + calPlatformTargets + ioPlatformTargets)
package.targets = packageTargets
