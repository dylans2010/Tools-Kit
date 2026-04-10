import SwiftUI

struct ReasoningToolView: View {
    @State private var question = ""
    @State private var reasoningResult = ""
    @State private var isThinking = false
    @State private var errorMessage: String?

    private let aiService = AIService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField("Enter a complex problem...", text: $question)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button(action: { Task { await think() } }) {
                    if isThinking {
                        ProgressView("AI is thinking...")
                            .padding()
                    } else {
                        Text("Start Reasoning")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(question.isEmpty || isThinking)

                if let error = errorMessage {
                    Text(error).foregroundColor(.red).font(.caption).padding()
                }

                if !reasoningResult.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Step-by-Step Reasoning", systemImage: "brain.head.profile")
                            .font(.headline)

                        Text(reasoningResult)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Reasoning Assistant")
    }

    private func think() async {
        isThinking = true
        errorMessage = nil
        do {
            reasoningResult = try await aiService.reason(problem: question)
        } catch {
            errorMessage = error.localizedDescription
        }
        isThinking = false
    }
}

struct ReasoningTool: Tool {
    let id = UUID()
    let name = "Reasoning Tool"
    let icon = "brain.head.profile"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Multi-step AI reasoning for complex problem solving"
    let requiresAPI = true
    var view: AnyView { AnyView(ReasoningToolView()) }
}
