// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DepDeck",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DepDeck",
            path: "Sources/DepDeck"
        ),
        .testTarget(
            name: "DepDeckTests",
            dependencies: ["DepDeck"],
            path: "Tests/DepDeckTests"
        )
    ]
)
