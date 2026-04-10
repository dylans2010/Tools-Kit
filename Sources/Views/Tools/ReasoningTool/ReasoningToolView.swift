import SwiftUI

struct ReasoningToolView: View {
    @State private var question = ""
    @State private var steps: [String] = []
    @State private var isThinking = false
    @State private var error: String?

    private let aiService = AIService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField("Enter a complex problem...", text: $question)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button(action: {
                    Task {
                        await think()
                    }
                }) {
                    if isThinking {
                        ProgressView().tint(.white)
                    } else {
                        Text("Start Reasoning")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(question.isEmpty || isThinking)

                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }

                if isThinking && steps.isEmpty {
                    ProgressView("AI is analyzing...")
                        .padding()
                }

                ForEach(steps, id: \.self) { step in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(step)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Reasoning Assistant")
    }

    private func think() async {
        guard !question.isEmpty else { return }

        steps = []
        isThinking = true
        error = nil

        let prompt = """
        Analyze the following problem and provide a multi-step reasoning process to solve it.
        Format your response as a bulleted list where each bullet point is a discrete step in the reasoning.

        Problem: \(question)
        """

        let request = AIRequest(
            prompt: prompt,
            systemPrompt: "You are a logical reasoning assistant. Break down problems into clear, actionable steps.",
            model: "google/gemini-2.0-flash-exp:free",
            attachments: nil
        )

        do {
            let result = try await aiService.process(request: request)
            let parsedSteps = result.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { $0.starts(with: "•") || $0.starts(with: "-") || $0.range(of: "^\\d+\\.", options: .regularExpression) != nil }
                .map { $0.replacingOccurrences(of: "^[•\\-\\d+\\.]\\s*", with: "", options: .regularExpression) }

            await MainActor.run {
                if parsedSteps.isEmpty {
                    self.steps = [result]
                } else {
                    self.steps = parsedSteps
                }
                isThinking = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isThinking = false
            }
        }
    }
}

struct ReasoningTool: Tool {
    let name = "Reasoning Tool"
    let icon = "brain.head.profile"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Multi-step AI reasoning for complex problem solving"
    let requiresAPI = true
    var view: AnyView { AnyView(ReasoningToolView()) }
}
