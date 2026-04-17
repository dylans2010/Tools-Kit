// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ToolsKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/MailCore/mailcore2", branch: "master"),
        .package(url: "https://github.com/appwrite/sdk-for-apple", from: "16.1.0")
    ],
    targets: [
        .executableTarget(
            name: "ToolsKit",
            dependencies: [
                .product(name: "MailCore2", package: "mailcore2"),
                .product(name: "Appwrite", package: "sdk-for-apple")
            ],
            path: "Sources"
        )
    ]
)
