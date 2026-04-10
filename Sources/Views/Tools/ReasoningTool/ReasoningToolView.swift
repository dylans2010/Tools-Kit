import SwiftUI

struct ReasoningToolView: View {
    @State private var question = ""
    @State private var steps: [String] = []
    @State private var isThinking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField("Enter a complex problem...", text: $question)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button("Start Reasoning") {
                    think()
                }
                .buttonStyle(.borderedProminent)

                if isThinking {
                    ProgressView("AI is thinking...")
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
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Reasoning Assistant")
    }

    private func think() {
        steps = []
        isThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            steps.append("Deconstructing the problem into core components...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                steps.append("Analyzing historical patterns and data...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    steps.append("Synthesizing a multi-step solution...")
                    isThinking = false
                }
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
