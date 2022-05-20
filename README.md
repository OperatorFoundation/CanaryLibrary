# CanaryLibrary

The core library that powers CanaryDesktop, CanaryDesktopLegacy, and CanaryLinux.

Canary is a tool for testing transport connections and gathering the packets for analysis. 

Canary will run a series of transport tests based on the configs that you provide. It is possible to test each transport on a different transport server based on what host information is provided in the transport config files. 

Currently only [Shadow](https://github.com/OperatorFoundation/ShadowSwift.git) tests are supported. Replicant support is underway, and will be capable of mimicking other transports when it is complete.

## Adding CanaryLibrary to your project

- Canary uses [SwiftPackageManager](https://github.com/apple/swift-package-manager.git).
- Canary requires that you also include the swift Logging library in your dependencies.

```
let package = Package(
  name: "MyApp",
    platforms: [.macOS(.v11)],
    products: [
        .executable(
            name: "MyApp",
            targets: ["MyApp"])],
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Canary.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2")],
    targets: [
        .executableTarget(
            name: "MyApp",
            dependencies: [
                           "Canary",
                           .product(name: "Logging", package: "swift-log")]),
        .testTarget(
            name: "MyAppTests",
            dependencies: ["MyApp"])],
    swiftLanguageVersions: [.v5])
```

## Using Canary

The Canary library provides a very simple API:

### Create an instance of the Canary class:
The Canary initializer takes the following Arguments:
  - **configPath: String** > The path to the directory that contains the transport config files.
  - *SavePath: String? > Optional (default: nil), the path where the test results should be saved.*
  - **logger: Logger** > An instance of a Swift Logger
  - *timesToRun: > Optional (default: 1), the number of times you would like the tests to run.*
  - *interface: String? > Optional, the network interface name (Canary will try to guess the correct interface for you if none is provided).* 
  - *debugPrints: Bool > Optional (default: false), indicates whether or not to show debug prints.*
  - *runWebTests: Bool > Optional (default: false), this is an experimental mode that will also test a few websites that are sometimes known to be blocked*

Only two of teh parameters are required and do not offer a default value. Quick setup:

`let canary = Canary(configPath: configDirectoryPath, logger: logger)`

Once you have a Canary instance you simply have to call runTest():

`canary.runTest()`

### Additional Notes:
- Transport configs should include their transport server IP and port, and should include the transport name in the name of the file.
- You should run Canary on the same platform it was compiled on
- You must run Canary with sudo in order for it to capture any data
- To run Canary with default settings simply provide the config directory and a Logger to the initializer.
