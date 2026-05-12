import Foundation

/// Engine responsible for deep semantic parsing and classification of communication content.
actor CommunicationIntelligenceEngine {
    static let shared = CommunicationIntelligenceEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Classifies the intent of a thread.
    func classifyIntent(for thread: MailThread) async throws -> MailIntent {
        let content = thread.messages.last?.body ?? thread.snippet
        let prompt = "Analyze this email and classify its primary intent: \(content)"
        let schema = """
        {
          "type": "object",
          "required": ["intent"],
          "properties": {
            "intent": { "type": "string", "enum": \(MailIntent.allCases.map { $0.rawValue }) }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
        struct Response: Codable, Sendable { let intent: MailIntent }
        let decoded = try JSONDecoder().decode(Response.self, from: Data(json.utf8))
        return decoded.intent
    }

    /// Extracts semantic entities from a thread.
    func extractEntities(for thread: MailThread) async throws -> ExtractedEntities {
        let content = thread.messages.map { $0.body }.joined(separator: "\n---\n")
        let prompt = "Extract all key entities (people, organizations, dates, deliverables, risks, etc.) from this conversation: \(content)"
        let schema = """
        {
          "type": "object",
          "properties": {
            "people": { "type": "array", "items": { "type": "string" } },
            "organizations": { "type": "array", "items": { "type": "string" } },
            "deadlines": { "type": "array", "items": { "type": "string", "format": "date-time" } },
            "deliverables": { "type": "array", "items": { "type": "string" } },
            "risks": { "type": "array", "items": { "type": "string" } },
            "locations": { "type": "array", "items": { "type": "string" } },
            "monetaryValues": { "type": "array", "items": { "type": "string" } }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExtractedEntities.self, from: Data(json.utf8))
    }

    /// Tracks the outcome of a conversation.
    func analyzeConversationOutcome(for thread: MailThread) async throws -> String {
        let content = thread.messages.map { "\($0.from): \($0.body)" }.joined(separator: "\n")
        let prompt = "What was the final outcome or current state of this conversation? Identify decisions made and pending items."
        return try await aiService.processText(prompt: prompt + "\n\nContent:\n" + content)
    }
}
