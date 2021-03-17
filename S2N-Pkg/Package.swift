// swift-tools-version:5.3
import PackageDescription

let S2N = Package(
    name: "S2N",
    products: [
        .library(
            name: "S2N",
            targets: ["S2N"]
        )
    ],
    dependencies: [.package(path: "../LibCrypto-Pkg"],
    targets: [
        .target(
            name: "S2N",
            dependencies: ["LibCrypto"],
            path: "../aws-common-runtime/s2n",
            exclude: ["bin", "cmake", "codebuild", "coverage", "docker-images", "docs", "lib", "libcrypto-build", "scram", "tests"],
            publicHeadersPath: "api"
        )
    ]
)
