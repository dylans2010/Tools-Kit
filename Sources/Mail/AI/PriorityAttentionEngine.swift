import Foundation

/// Multi-factor scoring system for urgency, importance, and historical behavior.
actor PriorityAttentionEngine {
    nonisolated(unsafe) static let shared = PriorityAttentionEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Calculates an attention score for a thread.
    func calculatePriority(for thread: MailThread) async throws -> AttentionScore {
        let content = thread.messages.last?.body ?? thread.snippet
        let prompt = "Analyze the priority of this email based on urgency, sender importance, and business impact: \(content)"
        let schema = """
        {
          "type": "object",
          "required": ["totalScore", "factors"],
          "properties": {
            "totalScore": { "type": "number" },
            "factors": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["name", "score", "weight"],
                "properties": {
                  "name": { "type": "string" },
                  "score": { "type": "number" },
                  "weight": { "type": "number" }
                }
              }
            }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
        return try JSONDecoder().decode(AttentionScore.self, from: Data(json.utf8))
    }

    /// Sorts threads based on attention score.
    func rankThreadsByAttention(_ threads: [MailThread]) async -> [MailThread] {
        var scoredThreads: [(MailThread, Double)] = []
        for thread in threads {
            let score = (try? await calculatePriority(for: thread).totalScore) ?? 0.0
            scoredThreads.append((thread, score))
        }
        return scoredThreads.sorted { $0.1 > $1.1 }.map { $0.0 }
    }
}
