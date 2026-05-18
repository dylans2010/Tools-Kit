import SwiftUI

struct TextDiffDevTool: DevTool {
    let id = "text-diff"
    let name = "Text Diff"
    let category = DevToolCategory.utilities
    let icon = "text.badge.minus"
    let description = "Compare two text blocks"

    func render() -> some View {
        TextDiffView()
    }
}

struct TextDiffView: View {
    @State private var text1 = ""
    @State private var text2 = ""

    var body: some View {
        Form {
            Section("Text A") {
                TextEditor(text: $text1)
                    .frame(height: 100)
            }
            Section("Text B") {
                TextEditor(text: $text2)
                    .frame(height: 100)
            }
            Section("Comparison") {
                if text1 == text2 {
                    Label("Texts are identical", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Texts differ", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
