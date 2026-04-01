import SwiftUI
struct TextFormatterView: View {
    @StateObject private var backend = TextFormatterBackend()
    var body: some View { VStack { TextEditor(text: $backend.text); Button("Uppercase") { backend.uppercase() } }.navigationTitle("Text Formatter") }
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
