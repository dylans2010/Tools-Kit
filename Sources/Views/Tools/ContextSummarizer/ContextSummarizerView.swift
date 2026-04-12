import SwiftUI

struct ContextSummarizerView: View {
    @StateObject private var backend = ContextSummarizerBackend()
    @State private var text: String = ""
    @State private var context: String = ""

    var body: some View {
        ToolDetailView(tool: ContextSummarizerTool()) {
            VStack(spacing: 24) {
                ToolInputSection("Context") {
                    TextField("What is this about? (e.g. Legal, Technical, Casual)", text: $context)
                        .padding()
                }

                ToolInputSection("Content") {
                    TextEditor(text: $text)
                        .frame(height: 150)
                        .padding(8)
                }

                Button(action: {
                    Task { await backend.summarize(text: text, context: context) }
                }) {
                    if backend.isProcessing {
                        ProgressView()
                    } else {
                        Text("Summarize with Context")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.isEmpty || backend.isProcessing)

                if !backend.summary.isEmpty {
                    ToolOutputView("Summary", value: backend.summary)
                }
            }
        }
    }
}

struct ContextSummarizerTool: Tool {
    let name = "Context Summarizer"
    let icon = "text.badge.star"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Generate smart summaries tailored to a specific context or field"
    let requiresAPI = true
    var view: AnyView { AnyView(ContextSummarizerView()) }
}
