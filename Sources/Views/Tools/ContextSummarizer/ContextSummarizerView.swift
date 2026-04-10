import SwiftUI

struct ContextSummarizerView: View {
    @State private var inputText = ""
    @State private var summary = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let aiService = AIService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextEditor(text: $inputText)
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    .padding()

                Button(action: { Task { await summarize() } }) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Summarize with Context")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(inputText.isEmpty || isLoading)

                if let error = errorMessage {
                    Text(error).foregroundColor(.red).font(.caption).padding()
                }

                if !summary.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Key Insights").font(.headline)
                        Text(summary)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Context Summarizer")
    }

    private func summarize() async {
        isLoading = true
        errorMessage = nil
        do {
            summary = try await aiService.summarize(text: inputText)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct ContextSummarizerTool: Tool {
    let id = UUID()
    let name = "Smart Summarizer"
    let icon = "text.justify.left"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "AI-powered summarization that understands document context"
    let requiresAPI = true
    var view: AnyView { AnyView(ContextSummarizerView()) }
}
