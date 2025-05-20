// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SalatMac",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/batoulapps/adhan-swift", from: "1.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SalatMac",
            dependencies: [
                .product(name: "Adhan", package: "adhan-swift")
            ],
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]),
    ]
)
