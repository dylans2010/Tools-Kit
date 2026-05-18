import SwiftUI

struct MarkdownPreviewDevTool: DevTool {
    let id = "markdown-preview"
    let name = "Markdown Preview"
    let category = DevToolCategory.utilities
    let icon = "text.bubble"
    let description = "Live preview of Markdown content"

    func render() -> some View {
        MarkdownPreviewView()
    }
}

struct MarkdownPreviewView: View {
    @StateObject private var viewModel = MarkdownPreviewViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Markdown Preview",
                description: "Write Markdown and see it rendered in real-time as formatted text.",
                icon: "text.bubble"
            )
            .padding()

            HStack {
                VStack {
                    Text("Editor").font(.caption.bold())
                    TextEditor(text: $viewModel.input)
                        .font(.system(.caption, design: .monospaced))
                }

                Divider()

                VStack {
                    Text("Preview").font(.caption.bold())
                    ScrollView {
                        Text(LocalizedStringKey(viewModel.input))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .padding()
        }
    }
}

class MarkdownPreviewViewModel: ObservableObject {
    @Published var input = "# Title\n\n- Item 1\n- Item 2\n\n**Bold Text**"
}
