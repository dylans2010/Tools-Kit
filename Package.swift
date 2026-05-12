// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ToolsKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/MailCore/mailcore2", branch: "master"),
        .package(url: "https://github.com/appwrite/sdk-for-apple", from: "16.1.0"),
        .package(url: "https://github.com/daily-co/daily-client-ios.git", from: "0.37.0"),
        .package(url: "https://github.com/tornikegomareli/Aurora.git", from: "0.3.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19")
    ],
    targets: [
        .executableTarget(
            name: "ToolsKit",
            dependencies: [
                .product(name: "MailCore2", package: "mailcore2"),
                .product(name: "Appwrite", package: "sdk-for-apple"),
                .product(name: "Daily", package: "daily-client-ios"),
                .product(name: "Aurora", package: "Aurora"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            path: "Sources"
        )
    ]
)
