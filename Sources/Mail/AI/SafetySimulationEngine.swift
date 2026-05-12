import Foundation

/// Engine for tone analysis, risk detection, and response simulation.
actor SafetySimulationEngine {
    static let shared = SafetySimulationEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Analyzes the safety and tone of a message.
    func analyzeSafety(for content: String) async throws -> SafetyAnalysis {
        let prompt = "Analyze the tone and communication risks in this text: \(content)"
        let schema = """
        {
          "type": "object",
          "required": ["tone", "riskLevel", "risks", "suggestedToneAdjustment"],
          "properties": {
            "tone": { "type": "string" },
            "riskLevel": { "type": "string", "enum": ["low", "medium", "high", "critical"] },
            "risks": { "type": "array", "items": { "type": "string" } },
            "suggestedToneAdjustment": { "type": "string" }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
        return try JSONDecoder().decode(SafetyAnalysis.self, from: Data(json.utf8))
    }

    /// Simulates the outcome of a reply.
    func simulateReplyOutcome(original: String, reply: String) async throws -> String {
        let prompt = """
        Analyze the original email and the proposed reply.
        Simulate the likely outcome and recipient's perception.

        Original: \(original)
        Reply: \(reply)
        """
        return try await aiService.processText(prompt: prompt)
    }

    /// Suggests alternative strategies for a communication scenario.
    func suggestStrategies(original: String) async throws -> [String] {
        let prompt = "Suggest three different communication strategies for responding to this email: \(original)"
        let result = try await aiService.processText(prompt: prompt)
        return result.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
}
