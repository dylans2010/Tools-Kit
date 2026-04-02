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
                StatCard(title: "Characters", value: "\(backend.characterCount)")
                StatCard(title: "Words", value: "\(backend.wordCount)")
                StatCard(title: "Sentences", value: "\(backend.sentenceCount)")
                StatCard(title: "Lines", value: "\(backend.lineCount)")
            }
        }
        .padding()
        .navigationTitle("Word Counter")
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct WordCounterTool: Tool {
    let name = "Word Counter"
    let icon = "textformat.123"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Count words in text"
    let requiresAPI = false
    var view: AnyView { AnyView(WordCounterView()) }
}
