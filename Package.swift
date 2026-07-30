// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Caffeine",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Caffeine", path: "Sources/Caffeine")
    ]
)
