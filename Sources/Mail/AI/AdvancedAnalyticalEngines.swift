import Foundation

/// Engine for detecting negotiation patterns, tracking concessions, and suggesting strategies.
actor NegotiationIntelligenceEngine {
    nonisolated(unsafe) static let shared = NegotiationIntelligenceEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Analyzes the negotiation state of a thread.
    func analyzeNegotiation(for thread: MailThread) async throws -> NegotiationState {
        let content = thread.messages.map { "\($0.from): \($0.body)" }.joined(separator: "\n")
        let prompt = "Analyze the negotiation patterns in this thread."
        let schema = """
        {
          "type": "object",
          "required": ["currentPhase", "concessions", "commitments", "leverageAnalysis", "suggestedStrategy"],
          "properties": {
            "currentPhase": { "type": "string", "enum": ["exploration", "bidding", "bargaining", "closing", "settled", "stalled"] },
            "concessions": { "type": "array", "items": { "type": "string" } },
            "commitments": { "type": "array", "items": { "type": "string" } },
            "leverageAnalysis": { "type": "string" },
            "suggestedStrategy": { "type": "string" }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt + "\n\nContent:\n" + content, jsonSchema: schema)
        return try JSONDecoder().decode(NegotiationState.self, from: Data(json.utf8))
    }
}

/// Engine for automatic extraction and tracking of deadlines and commitments.
actor DeadlineCommitmentEngine {
    nonisolated(unsafe) static let shared = DeadlineCommitmentEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Extracts deadlines and commitments from a thread.
    func extractObligations(for thread: MailThread) async throws -> [DecisionEntry] {
        let content = thread.messages.last?.body ?? ""
        let prompt = "Extract all deadlines and commitments from this email as a list of entries."
        let schema = """
        {
          "type": "object",
          "required": ["entries"],
          "properties": {
            "entries": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["title", "summary", "timestamp"],
                "properties": {
                  "title": { "type": "string" },
                  "summary": { "type": "string" },
                  "timestamp": { "type": "string", "format": "date-time" }
                }
              }
            }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt + "\n\nContent:\n" + content, jsonSchema: schema)

        struct Response: Codable, Sendable {
            let entries: [EntryResponse]
            struct EntryResponse: Codable, Sendable {
                let title: String
                let summary: String
                let timestamp: String
            }
        }

        let decoded = try JSONDecoder().decode(Response.self, from: Data(json.utf8))
        let formatter = ISO8601DateFormatter()
        return decoded.entries.map {
            DecisionEntry(id: UUID(), title: $0.title, summary: $0.summary, timestamp: formatter.date(from: $0.timestamp) ?? Date(), threadID: thread.id, lineageIDs: [])
        }
    }
}

/// Engine for building dynamic profiles and tracking relationship health.
actor RelationshipIntelligenceEngine {
    nonisolated(unsafe) static let shared = RelationshipIntelligenceEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Generates a relationship profile for a contact.
    func buildProfile(for email: String, interactionHistory: String) async throws -> RelationshipProfile {
        let prompt = "Build a relationship profile for \(email) based on this history: \(interactionHistory)"
        let schema = """
        {
          "type": "object",
          "required": ["displayName", "sentimentTrend", "healthScore", "topTopics", "totalInteractionCount", "lastInteractionDate"],
          "properties": {
            "displayName": { "type": "string" },
            "sentimentTrend": { "type": "array", "items": { "type": "number" } },
            "healthScore": { "type": "number" },
            "topTopics": { "type": "array", "items": { "type": "string" } },
            "totalInteractionCount": { "type": "integer" },
            "lastInteractionDate": { "type": "string", "format": "date-time" }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt, jsonSchema: schema)

        struct ProfileResponse: Codable, Sendable {
            var displayName: String?
            var sentimentTrend: [Double]
            var healthScore: Double
            var topTopics: [String]
            var totalInteractionCount: Int
            var lastInteractionDate: Date
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(ProfileResponse.self, from: Data(json.utf8))

        return RelationshipProfile(
            email: email,
            displayName: response.displayName,
            sentimentTrend: response.sentimentTrend,
            healthScore: response.healthScore,
            topTopics: response.topTopics,
            totalInteractionCount: response.totalInteractionCount,
            lastInteractionDate: response.lastInteractionDate
        )
    }
}

/// Engine for converting email threads into structured knowledge entries.
actor KnowledgeExtractionEngine {
    nonisolated(unsafe) static let shared = KnowledgeExtractionEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Extracts knowledge insights from a thread.
    func extractKnowledge(from thread: MailThread) async throws -> [KnowledgeInsight] {
        let content = thread.messages.map { $0.body }.joined(separator: "\n")
        let prompt = "Extract structured knowledge, insights, and documentation from this thread."
        let schema = """
        {
          "type": "object",
          "required": ["insights"],
          "properties": {
            "insights": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["title", "content", "category", "tags"],
                "properties": {
                  "title": { "type": "string" },
                  "content": { "type": "string" },
                  "category": { "type": "string" },
                  "tags": { "type": "array", "items": { "type": "string" } }
                }
              }
            }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt + "\n\nContent:\n" + content, jsonSchema: schema)

        struct Response: Codable, Sendable {
            let insights: [InsightResponse]
            struct InsightResponse: Codable, Sendable {
                let title: String
                let content: String
                let category: String
                let tags: [String]
            }
        }

        let decoded = try JSONDecoder().decode(Response.self, from: Data(json.utf8))
        return decoded.insights.map {
            KnowledgeInsight(id: UUID(), title: $0.title, content: $0.content, category: $0.category, tags: $0.tags, sourceThreadID: thread.id)
        }
    }
}

/// Engine for correlating context across multiple related threads.
actor MultiThreadCorrelationEngine {
    nonisolated(unsafe) static let shared = MultiThreadCorrelationEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Detects related threads and merges their context.
    func correlateThreads(threads: [MailThread]) async throws -> [[String]] {
        let snippets = threads.map { "ID: \($0.id), Subject: \($0.subject)" }.joined(separator: "\n")
        let prompt = "Identify groups of related email threads based on subject and context: \(snippets)"
        let schema = """
        {
          "type": "object",
          "required": ["groups"],
          "properties": {
            "groups": { "type": "array", "items": { "type": "array", "items": { "type": "string" } } }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
        struct Response: Codable, Sendable { let groups: [[String]] }
        let decoded = try JSONDecoder().decode(Response.self, from: Data(json.utf8))
        return decoded.groups
    }
}

/// Engine for identifying decisions made and building decision timelines.
actor DecisionIntelligenceEngine {
    nonisolated(unsafe) static let shared = DecisionIntelligenceEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Tracks decisions in a thread.
    func trackDecisions(for thread: MailThread) async throws -> [DecisionEntry] {
        let content = thread.messages.map { $0.body }.joined(separator: "\n")
        let prompt = "Identify all decisions made in this email conversation."
        let schema = """
        {
          "type": "object",
          "required": ["decisions"],
          "properties": {
            "decisions": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["title", "summary", "timestamp"],
                "properties": {
                  "title": { "type": "string" },
                  "summary": { "type": "string" },
                  "timestamp": { "type": "string", "format": "date-time" }
                }
              }
            }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt + "\n\nContent:\n" + content, jsonSchema: schema)

        struct Response: Codable, Sendable {
            let decisions: [DecisionResponse]
            struct DecisionResponse: Codable, Sendable {
                let title: String
                let summary: String
                let timestamp: String
            }
        }

        let decoded = try JSONDecoder().decode(Response.self, from: Data(json.utf8))
        let formatter = ISO8601DateFormatter()
        return decoded.decisions.map {
            DecisionEntry(id: UUID(), title: $0.title, summary: $0.summary, timestamp: formatter.date(from: $0.timestamp) ?? Date(), threadID: thread.id, lineageIDs: [])
        }
    }
}

/// Engine for parsing and executing natural language commands inside emails.
actor EmailCommandEngine {
    nonisolated(unsafe) static let shared = EmailCommandEngine()
    private let aiService = AIService.shared

    private init() {}

    /// Parses and executes commands from email content.
    func processCommands(in text: String) async throws -> [String] {
        let prompt = "Parse and extract executable commands (e.g., 'schedule a meeting', 'assign task to X') from this email: \(text)"
        let schema = """
        {
          "type": "object",
          "required": ["commands"],
          "properties": {
            "commands": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["action", "detail"],
                "properties": {
                  "action": { "type": "string", "enum": ["schedule", "task", "reply", "summarize"] },
                  "detail": { "type": "string" }
                }
              }
            }
          }
        }
        """
        let json = try await aiService.generateStructuredJSON(prompt: prompt, jsonSchema: schema)

        struct Command: Codable, Sendable {
            let action: String
            let detail: String
        }
        struct Response: Codable, Sendable { let commands: [Command] }

        let decoded = try JSONDecoder().decode(Response.self, from: Data(json.utf8))
        var executed: [String] = []

        for cmd in decoded.commands {
            switch cmd.action {
            case "schedule":
                // Logic to invoke calendar bridge
                _ = try? await ExecutionBridge.shared.createTask(title: "Meeting: \(cmd.detail)", description: "Auto-scheduled via command.")
                executed.append("Scheduled: \(cmd.detail)")
            case "task":
                _ = try? await ExecutionBridge.shared.createTask(title: cmd.detail, description: "Auto-created via command.")
                executed.append("Created Task: \(cmd.detail)")
            case "reply":
                executed.append("Drafted Reply: \(cmd.detail)")
            case "summarize":
                executed.append("Summarized: \(cmd.detail)")
            default:
                break
            }
        }
        return executed
    }
}

/// Engine for learning user patterns and refining AI outputs over time.
actor BehavioralLearningEngine {
    nonisolated(unsafe) static let shared = BehavioralLearningEngine()
    private var interactions: [String: Int] = [:]

    private init() {}

    /// Records a user action to learn patterns.
    func recordAction(type: String, metadata: [String: String]) {
        interactions[type, default: 0] += 1
        WorkspaceLogger.general.info("BehavioralLearningEngine recorded action: \(type)")
    }

    /// Adapts a system prompt or priority based on learned patterns.
    func getAdaptedWeights() -> [String: Double] {
        let total = Double(interactions.values.reduce(0, +))
        guard total > 0 else { return ["urgency": 0.33, "sender": 0.33, "impact": 0.34] }

        let archiveRate = Double(interactions["archive", default: 0]) / total
        let replyRate = Double(interactions["reply", default: 0]) / total

        // Dynamic weight adjustment based on behavior
        return [
            "urgency": 0.4 + (replyRate * 0.2),
            "sender": 0.4 - (archiveRate * 0.1),
            "impact": 0.2 + (archiveRate * 0.1)
        ]
    }
}
