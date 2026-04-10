import SwiftUI

struct SmartAutofillView: View {
    @State private var prompt = ""
    @State private var generatedContent = ""
    @State private var isGenerating = false
    @State private var error: String?

    private let aiService = AIService()

    var body: some View {
        VStack(spacing: 20) {
            TextField("What should I generate? (e.g. Email template)", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button(action: {
                Task {
                    await generate()
                }
            }) {
                if isGenerating {
                    ProgressView().tint(.white)
                } else {
                    Text("Generate Content")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(prompt.isEmpty || isGenerating)

            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }

            if !generatedContent.isEmpty {
                VStack(alignment: .leading) {
                    Text("Result").font(.headline)
                    TextEditor(text: .constant(generatedContent))
                        .frame(height: 200)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }
                .padding()
            }

            Spacer()
        }
        .navigationTitle("Smart Autofill")
    }

    private func generate() async {
        guard !prompt.isEmpty else { return }

        isGenerating = true
        error = nil

        let request = AIRequest(
            prompt: prompt,
            systemPrompt: "You are a content generation assistant. Infer the field type and context to generate appropriate content.",
            model: "google/gemini-2.0-flash-exp:free",
            attachments: nil
        )

        do {
            let result = try await aiService.process(request: request)
            await MainActor.run {
                self.generatedContent = result
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isGenerating = false
            }
        }
    }
}

struct SmartAutofillTool: Tool {
    let name = "Smart Autofill"
    let icon = "square.and.pencil"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "AI generator for templates, emails, and repetitive text"
    let requiresAPI = true
    var view: AnyView { AnyView(SmartAutofillView()) }
}
