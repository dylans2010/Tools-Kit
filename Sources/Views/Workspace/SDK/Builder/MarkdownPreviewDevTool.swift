import SwiftUI

struct MarkdownPreviewDevTool: DevTool {
    let id = "markdown-preview"
    let name = "Markdown Preview"
    let category = DevToolCategory.utilities
    let icon = "text.bubble"
    let description = "Live preview of Markdown content"

    func render() -> some View {
        MarkdownPreviewDevToolView()
    }
}

struct MarkdownPreviewDevToolView: View {
    @StateObject private var viewModel = MarkdownPreviewViewModel()
    @State private var viewMode = 0 // 0: Split, 1: Editor, 2: Render

    var body: some View {
        VStack(spacing: 0) {
            Picker("Display Mode", selection: $viewMode) {
                Label("Split", systemImage: "square.split.2x1").tag(0)
                Label("Edit", systemImage: "pencil.line").tag(1)
                Label("View", systemImage: "eye").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(.ultraThinMaterial)

            Group {
                if viewMode == 0 {
                    HStack(spacing: 0) {
                        editorView
                        Divider()
                        renderView
                    }
                } else if viewMode == 1 {
                    editorView
                } else {
                    renderView
                }
            }
        }
        .navigationTitle("Markdown Lab")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Headers & Lists") { viewModel.input = "# Title\n## Subtitle\n- Point A\n- Point B" }
                    Button("Formatting") { viewModel.input = "**Bold**, *Italic*, ~~Strikethrough~~" }
                    Button("Code Block") { viewModel.input = "```swift\nprint(\"Hello\")\n```" }
                    Divider()
                    Button("Clear All", role: .destructive) { viewModel.input = "" }
                } label: {
                    Image(systemName: "text.badge.plus")
                }
            }
        }
    }

    private var editorView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("MARKDOWN").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                Spacer()
                Button { UIPasteboard.general.string = viewModel.input } label: {
                    Image(systemName: "doc.on.doc").font(.system(size: 10))
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))

            TextEditor(text: $viewModel.input)
                .font(.system(size: 12, design: .monospaced))
                .padding(4)
                .background(Color(.systemBackground))
        }
    }

    private var renderView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("RENDERED").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))

            ScrollView {
                Text(LocalizedStringKey(viewModel.input))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(.systemBackground))
        }
    }
}

class MarkdownPreviewViewModel: ObservableObject {
    @Published var input = "# Title\n\n- Item 1\n- Item 2\n\n**Bold Text**"
}

#Preview {
    MarkdownPreviewDevToolView()
}
