// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PasteJack",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PasteJack",
            path: "Sources/PasteJack"
        ),
        .testTarget(
            name: "PasteJackTests",
            dependencies: ["PasteJack"],
            path: "Tests/PasteJackTests"
        )
    ]
)
