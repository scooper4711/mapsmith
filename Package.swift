// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FlipMapPrinter",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "FlipMapPrinter", targets: ["FlipMapPrinter"]),
        .library(name: "FlipMapCore", targets: ["FlipMapCore"]),
    ],
    targets: [
        .target(name: "FlipMapCore"),
        .executableTarget(name: "FlipMapPrinter", dependencies: ["FlipMapCore"]),
        .testTarget(name: "FlipMapCoreTests", dependencies: ["FlipMapCore"]),
    ]
)
