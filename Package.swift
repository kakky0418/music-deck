// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MusicDeck",
    defaultLocalization: "ja",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MusicDeck", targets: ["MusicDeckApp"]),
        .library(name: "MusicDeckCore", targets: ["MusicDeckCore"])
    ],
    targets: [
        .target(
            name: "MusicDeckCore",
            path: "Sources/MusicDeckCore"
        ),
        .executableTarget(
            name: "MusicDeckApp",
            dependencies: ["MusicDeckCore"],
            path: "Sources/MusicDeckApp"
        ),
        .testTarget(
            name: "MusicDeckCoreTests",
            dependencies: ["MusicDeckCore"],
            path: "Tests/MusicDeckCoreTests"
        )
    ]
)
