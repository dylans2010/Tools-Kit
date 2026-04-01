// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ToolsKit",
    platforms: [.iOS(.v17)],
    targets: [
        .executableTarget(name: "ToolsKit", path: "Sources")
    ]
)