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

    func generate() {
        let topicStr = topic.isEmpty ? "[Your Topic]" : topic
        var prompt = ""

        switch selectedType {
        case .creativeWriting:
            prompt = "Act as a professional creative writer. Write a compelling story about \(topicStr). Ensure the tone is engaging and uses vivid imagery."
        case .codeGeneration:
            prompt = "Act as an expert software engineer. Write a clean, efficient, and well-documented implementation of \(topicStr) in the most suitable programming language."
        case .imagePrompt:
            if selectedModel == .midjourney {
                prompt = "A hyper-realistic cinematic shot of \(topicStr), 8k resolution, Unreal Engine 5 render, depth of field, golden hour lighting --v 6.0 --ar 16:9"
            } else {
                prompt = "A high-quality digital art piece representing \(topicStr). Detailed textures, vibrant colors, professional lighting, centered composition."
            }
        case .dataAnalysis:
            prompt = "Act as a senior data scientist. Analyze the following scenario: \(topicStr). Provide a structured breakdown of key trends, potential outliers, and actionable insights."
        case .roleplay:
            prompt = "I want you to act as an expert in \(topicStr). Use your deep knowledge to answer questions, provide advice, and explain complex concepts in an easy-to-understand way."
        }

        if includeConstraints {
            prompt += "\n\nConstraints: Avoid clichés, maintain a professional tone, and keep the output concise yet comprehensive."
        }

        generatedPrompt = prompt
    }
}
