// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ContextBoard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ContextBoard",
            targets: ["ContextBoard"]
        ),
    ],
    dependencies: [
        // Phase 4: Global Hotkey package
        // .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "ContextBoard",
            dependencies: [
                // "HotKey",
            ],
            path: "ContextBoard",
            exclude: [
                "Info.plist",
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
            ]
        ),
        .testTarget(
            name: "ContextBoardTests",
            dependencies: ["ContextBoard"],
            path: "ContextBoardTests"
        ),
    ]
)
