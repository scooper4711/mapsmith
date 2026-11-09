// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mapsmith",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Mapsmith", targets: ["Mapsmith"]),
        .library(name: "MapsmithCore", targets: ["MapsmithCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/scooper4711/tabletop-kit.git", from: "0.17.0")
    ],
    targets: [
        .target(name: "MapsmithCore", dependencies: [.product(name: "TablesideShared", package: "tabletop-kit")]),
        .executableTarget(
            name: "Mapsmith",
            dependencies: ["MapsmithCore", .product(name: "TablesideShared", package: "tabletop-kit")]
        ),
        .testTarget(
            name: "MapsmithCoreTests",
            dependencies: ["MapsmithCore", .product(name: "TablesideShared", package: "tabletop-kit")]
        )
    ]
)
