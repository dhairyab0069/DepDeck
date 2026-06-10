// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DepDeckAcademy",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AcademyCore", targets: ["AcademyCore"]),
        .executable(name: "DepDeckWindowed", targets: ["DepDeckWindowed"])
    ],
    targets: [
        // The logic you will write, stage by stage.
        .target(name: "AcademyCore", path: "Sources/AcademyCore"),
        // The windowed app — it only comes alive once your stages pass.
        .executableTarget(
            name: "DepDeckWindowed",
            dependencies: ["AcademyCore"],
            path: "Sources/DepDeckWindowed"
        ),
        // The tests that grade your work: ./academy check <stage>
        .testTarget(
            name: "AcademyTests",
            dependencies: ["AcademyCore"],
            path: "Tests/AcademyTests"
        )
    ]
)
