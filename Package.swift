// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MarketTakingTrainer",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        // xtool expects exactly one library product: the app itself.
        .library(
            name: "TrainerApp",
            targets: ["TrainerApp"]
        ),
    ],
    targets: [
        // Pure game logic. No SwiftUI/UIKit; builds and tests on Linux.
        .target(name: "GameCore"),
        // Thin SwiftUI layer. Sources are wrapped in `#if canImport(SwiftUI)`
        // so `swift test` on Linux still builds the whole package.
        .target(
            name: "TrainerApp",
            dependencies: ["GameCore"]
        ),
        .testTarget(
            name: "GameCoreTests",
            dependencies: ["GameCore"]
        ),
    ]
)
