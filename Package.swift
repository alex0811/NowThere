// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NowThere",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "NowThereCore", targets: ["NowThereCore"]),
        .executable(name: "NowThere", targets: ["NowThere"])
    ],
    targets: [
        .target(name: "NowThereCore"),
        .executableTarget(
            name: "NowThere",
            dependencies: ["NowThereCore"]
        ),
        .testTarget(name: "NowThereCoreTests", dependencies: ["NowThereCore"]),
        .testTarget(name: "NowThereAppTests", dependencies: ["NowThere", "NowThereCore"])
    ]
)
