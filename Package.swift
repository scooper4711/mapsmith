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
        // Moves to the release with TablesideShared once scooper4711/tabletop-kit#28 is merged.
        .package(url: "https://github.com/scooper4711/tabletop-kit.git", branch: "feat/tableside-shared")
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
