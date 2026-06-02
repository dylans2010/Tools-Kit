import SwiftUI

struct PackageSwiftTemplateDevTool: DevTool {
    let id = "package-swift-template"
    let name = "Package.swift Template"
    let category: DevToolCategory = .automation
    let icon = "shippingbox"
    let description = "Template for Swift Package Manager manifest"

    func render() -> some View {
        Text("Package.swift Template")
            .font(.headline)
            .padding()
        Text("// swift-tools-version: 5.9\nimport PackageDescription\n\nlet package = Package(\n    name: \"MyLibrary\",\n    products: [\n        .library(name: \"MyLibrary\", targets: [\"MyLibrary\"]),\n    ],\n    targets: [\n        .target(name: \"MyLibrary\"),\n    ]\n)")
            .font(.system(.caption, design: .monospaced))
            .padding()
    }
}
