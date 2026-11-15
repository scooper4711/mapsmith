// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mapsmith",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .executable(name: "Mapsmith", targets: ["Mapsmith"]),
        .library(name: "MapsmithCore", targets: ["MapsmithCore"]),
        // The app shared by the Mac executable and the iPad project in ios/.
        .library(name: "MapsmithUI", targets: ["MapsmithUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/scooper4711/tabletop-kit.git", from: "1.2.0")
    ],
    targets: [
        .target(name: "MapsmithCore", dependencies: [.product(name: "TablesideShared", package: "tabletop-kit")]),
        .target(
            name: "MapsmithUI",
            dependencies: [
                "MapsmithCore", .product(name: "AppNotices", package: "tabletop-kit"),
                .product(name: "TablesideShared", package: "tabletop-kit")
            ]
        ),
        .executableTarget(name: "Mapsmith", dependencies: ["MapsmithUI"]),
        .testTarget(
            name: "MapsmithCoreTests",
            dependencies: ["MapsmithCore", .product(name: "TablesideShared", package: "tabletop-kit")]
        )
    ]
)
