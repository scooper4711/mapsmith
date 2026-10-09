// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mapsmith",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Mapsmith", targets: ["Mapsmith"]),
        .library(name: "MapsmithCore", targets: ["MapsmithCore"]),
    ],
    targets: [
        .target(name: "MapsmithCore"),
        .executableTarget(name: "Mapsmith", dependencies: ["MapsmithCore"]),
        .testTarget(name: "MapsmithCoreTests", dependencies: ["MapsmithCore"]),
    ]
)
