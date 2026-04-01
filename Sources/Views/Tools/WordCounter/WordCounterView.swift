import SwiftUI
struct WordCounterView: View {
    @StateObject private var backend = WordCounterBackend()
    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $backend.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray, width: 1)
            HStack(spacing: 24) {
                Label("\(backend.wordCount) words", systemImage: "textformat.abc")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Word Counter")
    }
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
