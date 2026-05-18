import SwiftUI

struct MarkdownPreviewTool: DevTool {
    let id = UUID()
    let name = "Markdown Preview"
    let category: DevToolCategory = .utilities
    let icon = "text.badge.checkmark"
    let description = "Live preview of Markdown text"
    func render() -> some View { MarkdownPreviewDevToolView() }
}

struct MarkdownPreviewDevToolView: View {
    @State private var input = "# Hello World\n\nThis is **bold** and *italic* text.\n\n- Item 1\n- Item 2\n- Item 3\n\n> A blockquote\n\n`inline code`\n\n[Link](https://apple.com)"
    @State private var showPreview = true

    var body: some View {
        Form {
            Section {
                Toggle("Show Preview", isOn: $showPreview)
            }
            Section("Markdown") {
                TextEditor(text: $input)
                    .frame(minHeight: 150)
                    .font(.system(.body, design: .monospaced))
            }
            if showPreview {
                Section("Preview") {
                    let cleaned = input.replacingOccurrences(of: "\\n", with: "\n")
                    Text(LocalizedStringKey(cleaned))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
            }
            Section("Stats") {
                let lines = input.components(separatedBy: .newlines)
                LabeledContent("Characters", value: "\(input.count)")
                LabeledContent("Words", value: "\(input.split(separator: " ").count)")
                LabeledContent("Lines", value: "\(lines.count)")
            }
        }
        .navigationTitle("Markdown Preview")
    }
}
