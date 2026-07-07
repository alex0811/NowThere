// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NowThere",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "NowThereCore", targets: ["NowThereCore"])
    ],
    targets: [
        .target(name: "NowThereCore"),
        .testTarget(name: "NowThereCoreTests", dependencies: ["NowThereCore"])
    ]
)
