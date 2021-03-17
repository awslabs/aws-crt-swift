// swift-tools-version:5.3
import PackageDescription

let package = Package(
name: "LibCrypto",
products: [
    .library(
        name: "LibCrypto",
        targets: ["LibCrypto"]
    )
],
targets: [
    .systemLibrary(
        name: "LibCrypto",
        pkgConfig: "openssl",
        providers: [
            .apt(["openssl libssl-dev"])
//add this back when swift pm get's their crap together \\  .yum(["openssl openssl-devel"])
        ]
    )
])
