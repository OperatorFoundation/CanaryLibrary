// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Canary",
    platforms: [.macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Canary",
            targets: ["Canary"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .exact("1.0.3")),
        .package(url: "https://github.com/OperatorFoundation/AdversaryLabClientSwift", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Gardener.git", from: "0.0.48"),
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwiftClient.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/SwiftHexTools.git", from: "1.2.5"),
        .package(url: "https://github.com/OperatorFoundation/swift-netutils.git", from: "4.3.0"),
        .package(url: "https://github.com/OperatorFoundation/Transmission.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Canary",
            dependencies: [
                "Gardener",
                "ReplicantSwiftClient",
                "ShadowSwift",
                "SwiftHexTools",
                "Transmission",
                .product(name: "AdversaryLabClientCore", package: "AdversaryLabClientSwift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NetUtils", package: "swift-netutils")
            ]),
        .testTarget(
            name: "CanaryTests",
            dependencies: ["Canary"]),
    ],
    swiftLanguageVersions: [.v5]
)
