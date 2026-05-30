import SwiftUI

struct MarkdownPreviewerView: View {
    @State private var markdownText = """
    # Markdown Preview

    This is a live preview tool for **Markdown** content.

    ## Features
    - **Bold** and *Italic* text
    - [Links](https://apple.com)
    - Lists
      1. Item 1
      2. Item 2

    ```swift
    func hello() {
        print("Hello, Developer!")
    }
    ```
    """

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Editor").font(.headline)
                TextEditor(text: $markdownText)
                    .font(.system(.subheadline, design: .monospaced))
                    .frame(height: 200)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Preview").font(.headline)
                ScrollView {
                    SDKMarkdownView(content: markdownText)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }
            .padding()
        }
        .navigationTitle("Markdown Previewer")
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
