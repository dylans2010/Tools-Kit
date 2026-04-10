import SwiftUI

struct ContextSummarizerView: View {
    @State private var inputText = ""
    @State private var summary = ""
    @State private var isLoading = false
    @State private var error: String?

    private let aiService = AIService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextEditor(text: $inputText)
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    .padding()

                Button(action: {
                    Task {
                        await summarize()
                    }
                }) {
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

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }

                if !summary.isEmpty {
                    VStack(alignment: .leading) {
                        Text("AI Summary & Key Insights").font(.headline)
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
        guard !inputText.isEmpty else { return }

        isLoading = true
        error = nil

        let prompt = """
        Provide a detailed summary of the following text, including:
        - A concise overview
        - Key points as a bulleted list
        - Recommended action items (if any)

        Text:
        \(inputText)
        """

        let request = AIRequest(
            prompt: prompt,
            systemPrompt: "You are an expert at synthesizing information and providing structured summaries.",
            model: "google/gemini-2.0-flash-exp:free",
            attachments: nil
        )

        do {
            let result = try await aiService.process(request: request)
            await MainActor.run {
                self.summary = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
}

struct ContextSummarizerTool: Tool {
    let name = "Smart Summarizer"
    let icon = "text.justify.left"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "AI-powered summarization that understands document context"
    let requiresAPI = true
    var view: AnyView { AnyView(ContextSummarizerView()) }
}
