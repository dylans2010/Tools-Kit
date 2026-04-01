import SwiftUI
struct TextFormatterView: View {
    @StateObject private var backend = TextFormatterBackend()
    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $backend.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray, width: 1)
            HStack {
                Button("UPPERCASE") { backend.uppercase() }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
