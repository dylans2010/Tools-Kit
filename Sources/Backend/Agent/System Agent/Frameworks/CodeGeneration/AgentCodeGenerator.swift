import Foundation

final class AgentCodeGenerator {
    private let formatter = AgentCodeFormatter()
    private let aiService: AIService

    init(aiService: AIService = .shared) {
        self.aiService = aiService
    }

    func generate(from prompt: String, language: String) async throws -> String {
        let systemPrompt = "You are an expert software engineer. Generate ONLY the requested \(language) code without any explanation or markdown markers."
        let generatedCode = try await aiService.processText(prompt: prompt, systemPrompt: systemPrompt)
        return formatter.format(code: generatedCode, language: language)
    }
}
