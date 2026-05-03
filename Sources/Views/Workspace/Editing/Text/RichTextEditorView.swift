import SwiftUI

struct RichTextEditorView: View {
    @Binding var text: String
    @State private var selectedRange: NSRange = NSRange()

    var body: some View {
        VStack {
            HStack {
                Button(action: { applyStyle(.bold) }) {
                    Image(systemName: "bold")
                }
                Button(action: { applyStyle(.italic) }) {
                    Image(systemName: "italic")
                }
                Button(action: { applyStyle(.underline) }) {
                    Image(systemName: "underline")
                }
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground))

            TextEditor(text: $text)
                .padding()
        }
    }

    private func applyStyle(_ style: TextStyle) {
        let prefix: String
        let suffix: String

        switch style {
        case .bold:
            prefix = "**"; suffix = "**"
        case .italic:
            prefix = "*"; suffix = "*"
        case .underline:
            prefix = "__"; suffix = "__"
        }

        // Simulating Markdown-style formatting for the functional suite
        text = prefix + text + suffix
    }

    enum TextStyle {
        case bold, italic, underline
    }
}
