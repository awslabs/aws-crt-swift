// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "S2N",
    products: [
        .library(
            name: "S2N",
            targets: ["S2N"]
        ),
        .library(
            name: "LibCrypto",
            targets: ["LibCrypto"]
        )
    ],
    targets: [
        .target(
            name: "S2N",
            dependencies: ["LibCrypto"],
            path: "s2n",
            exclude: ["bin", "cmake", "codebuild", "coverage", "docker-images",
                      "docs", "lib", "pq-crypto", "libcrypto-build", "scram", "tests",
                      "s2n.mk", "Makefile", "stuffer/Makefile", "crypto/Makefile",
                      "tls/Makefile", "utils/Makefile", "error/Makefile",
                      "extensions/Makefile", "tls/extensions/Makefile",
                      "codecov.yml", "scripts/", "tests", "cmake", "codebuild", "CONTRIBUTING.md",
                      "LICENSE", "format-check.sh", "NOTICE", "builder.json",
                      "sanitizer-blacklist.txt", "CMakeLists.txt", "README.md",
                      "CODE_OF_CONDUCT.md", "build-deps.sh"]
,
            publicHeadersPath: "api",
            cSettings: [
                .headerSearchPath("./"),
                .define("POSIX_C_SOURCE=200809L"),
                .define("S2N_NO_PQ")
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
    ]
)
