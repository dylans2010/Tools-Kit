import SwiftUI
struct TextFormatterView: View {
    @StateObject private var backend = TextFormatterBackend()
    var body: some View {
        VStack(spacing: 20) {
            TextEditor(text: $backend.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray, width: 1)

            Button("Uppercase") {
                backend.uppercase()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Text Formatter")
    }
}
struct TextFormatterTool: Tool {
    let name = "Text Formatter"
    let icon = "text.badge.plus"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Format text"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 1
    var view: AnyView { AnyView(TextFormatterView()) }
}
