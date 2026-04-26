import Foundation

struct AgentAIService {
    let aiService: AIService

    init(aiService: AIService = .shared) {
        self.aiService = aiService
    }

    func sendSingleTurn(prompt: String, systemPrompt: String = "You are a helpful assistant.") async throws -> String {
        try await aiService.processText(prompt: prompt, systemPrompt: systemPrompt)
    }
}
