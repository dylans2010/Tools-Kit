import SwiftUI

struct WordCounterView: View {
    @StateObject private var backend = WordCounterBackend()

    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $backend.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Characters", value: "\(backend.characterCount)", icon: "character.cursor.ibeam", color: .blue)
                StatCard(title: "Words", value: "\(backend.wordCount)", icon: "textformat", color: .orange)
                StatCard(title: "Sentences", value: "\(backend.sentenceCount)", icon: "text.quote", color: .green)
                StatCard(title: "Lines", value: "\(backend.lineCount)", icon: "list.number", color: .purple)
            }
        }
        .padding()
        .navigationTitle("Word Counter")
    }
}

struct WordCounterTool: Tool, Sendable {
    let name = "Word Counter"
    let icon = "textformat.123"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Count words in text"
    let requiresAPI = false
    var view: AnyView { AnyView(WordCounterView()) }
}
