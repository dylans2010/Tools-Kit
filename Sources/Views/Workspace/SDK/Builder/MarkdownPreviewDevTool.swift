import SwiftUI

struct MarkdownPreviewDevTool: DevTool {
    let id = "markdown-preview"
    let name = "Markdown Preview"
    let category = DevToolCategory.utilities
    let icon = "text.below.photo"
    let description = "Preview Markdown rendered text"

    func render() -> some View {
        MarkdownPreviewView()
    }
}

struct MarkdownPreviewView: View {
    @State private var inputText = "# Hello\n\nThis is **Markdown** preview."

    var body: some View {
        VStack {
            TextEditor(text: $inputText)
                .frame(height: 150)
                .padding()
                .background(Color.secondary.opacity(0.1))

            Divider()

            ScrollView {
                Text(LocalizedStringKey(inputText))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }
}
