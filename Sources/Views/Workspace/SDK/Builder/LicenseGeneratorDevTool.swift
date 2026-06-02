import SwiftUI

struct LicenseGeneratorDevTool: DevTool {
    let id = "license-gen"
    let name = "License Generator"
    let category: DevToolCategory = .utilities
    let icon = "doc.plaintext"
    let description = "Generate MIT, Apache, or GNU license files"

    func render() -> some View {
        List {
            Text("MIT License").font(.headline)
            Text("Copyright (c) \(Calendar.current.component(.year, from: Date())) [Full Name]\n\nPermission is hereby granted, free of charge...")
                .font(.system(.caption, design: .monospaced))
        }
    }
}
