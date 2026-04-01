import SwiftUI
struct WordCounterView: View {
    @StateObject private var backend = WordCounterBackend()
    var body: some View { VStack { TextEditor(text: $backend.text); Text("Words: \(backend.wordCount)") }.navigationTitle("Word Counter") }
}
struct WordCounterTool: Tool {
    let name = "Word Counter"
    let icon = "textformat.123"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Count words in text"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 1
    var view: AnyView { AnyView(WordCounterView()) }
}
