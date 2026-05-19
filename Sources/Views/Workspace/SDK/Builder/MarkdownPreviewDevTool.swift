import SwiftUI

struct MarkdownPreviewDevTool: DevTool {
    let id = "markdown-preview"
    let name = "Markdown Preview"
    let category = DevToolCategory.utilities
    let icon = "text.bubble"
    let description = "Live preview of Markdown with templates and export"

    func render() -> some View {
        MarkdownPreviewDevToolView()
    }
}

struct MarkdownPreviewDevToolView: View {
    @StateObject private var viewModel = MarkdownPreviewViewModel()
    @State private var showPreview = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $showPreview) {
                Text("Editor").tag(false)
                Text("Preview").tag(true)
            }
            .pickerStyle(.segmented)
            .padding()

            if showPreview {
                ScrollView {
                    Text(LocalizedStringKey(viewModel.input))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            } else {
                TextEditor(text: $viewModel.input)
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal)
            }

            Divider()

            Form {
                Section("Templates") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MarkdownPreviewViewModel.templates, id: \.name) { template in
                                Button(template.name) {
                                    viewModel.input = template.content
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }

                Section("Quick Insert") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button("H1") { viewModel.insert("# ") }
                            Button("H2") { viewModel.insert("## ") }
                            Button("H3") { viewModel.insert("### ") }
                            Button("Bold") { viewModel.wrap("**") }
                            Button("Italic") { viewModel.wrap("*") }
                            Button("Code") { viewModel.wrap("`") }
                            Button("Link") { viewModel.insert("[text](url)") }
                            Button("Image") { viewModel.insert("![alt](url)") }
                            Button("List") { viewModel.insert("- ") }
                            Button("Task") { viewModel.insert("- [ ] ") }
                            Button("Quote") { viewModel.insert("> ") }
                            Button("HR") { viewModel.insert("\n---\n") }
                            Button("Table") { viewModel.insert("\n| Col1 | Col2 |\n|------|------|\n| Data | Data |\n") }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                Section("Statistics") {
                    HStack {
                        LabeledContent("Characters", value: "\(viewModel.input.count)")
                        Spacer()
                        LabeledContent("Words", value: "\(viewModel.wordCount)")
                        Spacer()
                        LabeledContent("Lines", value: "\(viewModel.lineCount)")
                    }
                    .font(.caption)
                }

                Section {
                    HStack {
                        Button {
                            UIPasteboard.general.string = viewModel.input
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            let tempDir = FileManager.default.temporaryDirectory
                            let fileURL = tempDir.appendingPathComponent("preview.md")
                            try? viewModel.input.write(to: fileURL, atomically: true, encoding: .utf8)
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                        Button("Clear") { viewModel.input = "" }
                            .buttonStyle(.bordered).controlSize(.small)
                    }
                }
            }
            .frame(height: 280)
        }
    }
}

class MarkdownPreviewViewModel: ObservableObject {
    @Published var input = "# Hello World\n\nThis is a **markdown** preview.\n\n- Item 1\n- Item 2\n\n> A blockquote\n\n```\ncode block\n```"

    var wordCount: Int {
        input.split(separator: " ").count
    }

    var lineCount: Int {
        input.components(separatedBy: .newlines).count
    }

    func insert(_ text: String) {
        input += text
    }

    func wrap(_ delimiter: String) {
        input += "\(delimiter)text\(delimiter)"
    }

    struct Template: Identifiable {
        let id = UUID()
        let name: String
        let content: String
    }

    static let templates: [Template] = [
        Template(name: "README", content: "# Project Name\n\n## Description\nA brief description.\n\n## Installation\n```\nnpm install\n```\n\n## Usage\n```swift\nimport MyLib\n```\n\n## License\nMIT"),
        Template(name: "Blog Post", content: "# Blog Title\n\n*Published: \(Date().formatted())*\n\n## Introduction\nYour intro here.\n\n## Main Content\nYour content.\n\n## Conclusion\nWrap up."),
        Template(name: "API Doc", content: "# API Endpoint\n\n## `GET /api/resource`\n\n### Parameters\n| Name | Type | Required |\n|------|------|----------|\n| id | string | Yes |\n\n### Response\n```json\n{\"status\": \"ok\"}\n```"),
        Template(name: "Changelog", content: "# Changelog\n\n## [1.0.0] - 2024-01-01\n### Added\n- Feature A\n- Feature B\n\n### Fixed\n- Bug fix\n\n### Changed\n- Updated dependency"),
    ]
}

#Preview {
    MarkdownPreviewDevToolView()
}
