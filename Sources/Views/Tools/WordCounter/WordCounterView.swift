import SwiftUI
struct WordCounterView: View {
    @StateObject private var backend = WordCounterBackend()
    var body: some View {
        VStack(spacing: 20) {
            TextEditor(text: $backend.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray, width: 1)

            Text("Words: \(backend.wordCount)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
