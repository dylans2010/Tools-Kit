// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ToolsKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/MailCore/mailcore2", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "ToolsKit",
            dependencies: [
                .product(name: "MailCore2", package: "mailcore2")
            ],
            path: "Sources"
        )
    ]
)
