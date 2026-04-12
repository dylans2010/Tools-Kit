import Foundation

enum PromptAIModel: String, CaseIterable {
    case gpt4 = "GPT-4"
    case claude = "Claude 3"
    case dalle = "DALL-E 3"
    case midjourney = "Midjourney"
    case stableDiffusion = "Stable Diffusion"
}

enum PromptType: String, CaseIterable {
    case creativeWriting = "Creative Writing"
    case codeGeneration = "Code Generation"
    case imagePrompt = "Image Generation"
    case dataAnalysis = "Data Analysis"
    case roleplay = "Expert Roleplay"
}

class PromptGeneratorBackend: ObservableObject {
    @Published var generatedPrompt = ""
    @Published var topic = ""
    @Published var selectedModel: PromptAIModel = .gpt4
    @Published var selectedType: PromptType = .creativeWriting
    @Published var includeConstraints = true
    @Published var isProcessing = false

    @MainActor
    func generate() async {
        isProcessing = true
        defer { isProcessing = false }

        let topicStr = topic.isEmpty ? "[Your Topic]" : topic
        let instructions = includeConstraints
            ? "Include constraints and a structured output format."
            : "No extra constraints."

        let prompt = """
        Create one high quality \(selectedType.rawValue.lowercased()) prompt for \(selectedModel.rawValue).
        Topic: \(topicStr)
        \(instructions)
        Return only the final prompt text.
        """

        do {
            generatedPrompt = try await AIService.shared.generateResponse(prompt: prompt)
        } catch {
            generatedPrompt = "Failed to generate prompt: \(error.localizedDescription)"
        }
    }
}
