// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeashCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "LeashCore", targets: ["LeashCore"])
    ],
    targets: [
        .target(name: "LeashCore"),
        .testTarget(name: "LeashCoreTests", dependencies: ["LeashCore"]),
    ]
)
