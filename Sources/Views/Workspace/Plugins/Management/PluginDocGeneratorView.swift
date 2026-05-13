
import SwiftUI

struct PluginDocGeneratorView: View {
    let plugin: PluginDefinition
    @State private var generatedMarkdown: String = ""
    @State private var isExported = false

    var body: some View {
        VStack(spacing: 0) {
            if generatedMarkdown.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass").font(.system(size: 64)).foregroundStyle(.blue)
                    Text("No Documentation Generated").font(.headline)
                    Button("Generate from Definition") { generate() }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(generatedMarkdown)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Button("Regenerate") { generate() }
                    Spacer()
                    Button(isExported ? "Saved to Pasteboard" : "Copy Markdown") {
                        UIPasteboard.general.string = generatedMarkdown
                        isExported = true
                    }
                }
                .padding()
                .background(.thinMaterial)
            }
        }
        .navigationTitle("Doc Generator")
    }

    private func generate() {
        var md = "# \(plugin.name) Documentation\n\n"
        md += "## Overview\n\(plugin.description)\n\n"
        md += "## Identity\n- **Identifier:** `\(plugin.identifier)`\n- **Author:** \(plugin.author)\n- **Version:** \(plugin.version)\n\n"

        md += "## Capabilities\n"
        for cap in plugin.capabilities {
            md += "- `\(cap.rawValue)` (\(cap.displayName)): \(cap.description)\n"
        }

        if !plugin.endpoints.isEmpty {
            md += "\n## External Endpoints\n"
            for ep in plugin.endpoints {
                md += "### \(ep.name)\n"
                md += "- **URL:** `\(ep.baseURL)\(ep.path)`\n"
                md += "- **Method:** `\(ep.method.rawValue)`\n"
            }
        }

        generatedMarkdown = md
        isExported = false
    }
}
