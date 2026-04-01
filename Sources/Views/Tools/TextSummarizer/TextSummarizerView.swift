import SwiftUI

struct TextSummarizerView: View {
    @StateObject private var backend = TextSummarizerBackend()

    var body: some View {
        Form {
            Section(header: Text("Long Text")) {
                TextEditor(text: $backend.inputText)
                    .frame(height: 200)
            }

            Section {
                Button("Summarize with AI") {
                    backend.summarize()
                }
                .disabled(backend.isLoading)
            }

            Section(header: Text("Summary Result")) {
                if backend.isLoading {
                    ProgressView("Summarizing...")
                } else {
                    Text(backend.summaryText)
                        .padding()
                }
            }
        }
        .navigationTitle("Text Summarizer")
    }
}

struct TextSummarizerTool: Tool {
    let name = "Text Summarizer"
    let icon = "text.quote"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "AI-powered text summarization"

    var view: AnyView {
        AnyView(TextSummarizerView())
    }
}
