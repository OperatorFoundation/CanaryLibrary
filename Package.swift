// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Canary",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Canary",
            targets: ["Canary"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/OperatorFoundation/AdversaryLabClientSwift", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Gardener.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwift.git", from: "2.0.0"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift.git", from: "4.0.0"),
        .package(url: "https://github.com/OperatorFoundation/Starbridge.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/swift-netutils.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Canary",
            dependencies: [
                "Gardener",
                "ReplicantSwift",
                "ShadowSwift",
                "Starbridge",
                .product(name: "AdversaryLabClientCore", package: "AdversaryLabClientSwift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NetUtils", package: "swift-netutils")
            ]),
        .testTarget(
            name: "CanaryTests",
            dependencies: ["Canary"]),
    ],
    swiftLanguageVersions: [.v5]
)
