import Foundation

class MailAIService {
    static let shared = MailAIService()
    private let aiService = AIService.shared
    private let settingsManager = AIChatSettingsManager.shared
    private let aiDecoder = AIResponseDecoder()

    struct PriorityDigest {
        let summaryMarkdown: String
        let priorityThreadIDs: [String]
    }

    private struct PriorityDigestResponse: Codable {
        let summary_markdown: String
        let priority_thread_ids: [String]
    }

    private func preferredModelID() async -> String? {
        await MainActor.run {
            let modelID = settingsManager.settings.modelID.trimmingCharacters(in: .whitespacesAndNewlines)
            return modelID.isEmpty ? nil : modelID
        }
    }

    private func processMailPrompt(
        prompt: String,
        systemPrompt: String = ""
    ) async throws -> String {
        try await aiService.processText(
            prompt: prompt,
            systemPrompt: systemPrompt,
            model: await preferredModelID()
        )
    }

    func catchUp(unreadThreads: [MailThread]) async throws -> String {
        guard UserDefaults.standard.bool(forKey: "mail.settings.ai.autoSummarize") else {
            return "Summarization is disabled in settings."
        }
        guard !unreadThreads.isEmpty else {
            return "You are all caught up. No unread emails were found."
        }

        let threads = unreadThreads
            .sorted { $0.lastMessageDate > $1.lastMessageDate }
            .prefix(12)

        let context = threads.map { thread in
            "From: \(thread.participants.joined(separator: ", ")), Subject: \(thread.subject), Snippet: \(thread.snippet)"
        }.joined(separator: "\n---\n")

        let prompt = """
        Summarize these unread emails for a quick catch-up.
        Respond in concise markdown only.
        Keep it short (max 110 words).
        Format exactly with sections:
        ### Urgent
        ### Important
        ### Informational
        Include only the most relevant emails and one next action per bullet.
        Emails:
        \(context)
        """

        return try await processMailPrompt(prompt: prompt)
    }

    func priorityDigest(unreadThreads: [MailThread]) async throws -> PriorityDigest {
        guard UserDefaults.standard.bool(forKey: "mail.settings.ai.autoSummarize") else {
            return PriorityDigest(summaryMarkdown: "Summarization is disabled in settings.", priorityThreadIDs: [])
        }
        guard !unreadThreads.isEmpty else {
            return PriorityDigest(
                summaryMarkdown: "### Priority Emails\nNo unread emails were found.",
                priorityThreadIDs: []
            )
        }

        let threads = unreadThreads
            .sorted { $0.lastMessageDate > $1.lastMessageDate }
            .prefix(40)

        let context = threads.map { thread in
            "ID: \(thread.id) | Subject: \(thread.subject) | From: \(thread.participants.joined(separator: ", ")) | Snippet: \(thread.snippet)"
        }.joined(separator: "\n")

        let schema = """
        {
          "type": "object",
          "required": ["summary_markdown", "priority_thread_ids"],
          "properties": {
            "summary_markdown": { "type": "string" },
            "priority_thread_ids": { "type": "array", "items": { "type": "string" } }
          }
        }
        """

        let prompt = """
        Analyze every email below and identify ONLY the high-priority emails.
        Criteria for Priority:
        1. Urgency: Keywords like 'urgent', 'ASAP', 'deadline', 'emergency', 'immediately'.
        2. Importance: Communication from key stakeholders, bosses, or known high-importance senders.
        3. Recency: Very recent unread messages that require immediate action.
        4. Impact: High business or personal impact tasks.

        Return JSON ONLY.
        Emails:
        \(context)
        """

        let json = try await aiService.generateStructuredJSON(
            prompt: prompt,
            jsonSchema: schema,
            systemPrompt: ""
        )

        let decoded = try JSONDecoder().decode(PriorityDigestResponse.self, from: json.data(using: .utf8)!)
        return PriorityDigest(summaryMarkdown: decoded.summary_markdown, priorityThreadIDs: decoded.priority_thread_ids)
    }

    func summarizeThread(_ thread: MailThread) async throws -> String {
        guard UserDefaults.standard.bool(forKey: "mail.settings.ai.autoSummarize") else {
            return "Summarization is disabled in settings."
        }
        let content = thread.messages
            .map { "\($0.from): \($0.body.trimmingCharacters(in: .whitespacesAndNewlines))" }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !content.isEmpty else {
            return "This thread has no readable content to summarize yet."
        }

        let prompt = """
        Summarize the following email thread and extract key points.
        Include: decisions made, pending questions, and deadlines if present.

        \(content)
        """
        return try await processMailPrompt(prompt: prompt)
    }

    func generateReply(for message: MailMessage, context: String) async throws -> String {
        let messageBody = message.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = """
        Write a clear, professional reply to this email.
        Original email:
        \(messageBody)

        Additional context for the reply:
        \(context)
        """
        return try await processMailPrompt(prompt: prompt, systemPrompt: "")
    }

    // MARK: - Advanced Intelligence

    func classifyIntent(for thread: MailThread) async throws -> String {
        let snippet = thread.snippet
        let prompt = "Classify the intent of this email thread (e.g., meeting_request, inquiry, announcement, task_assignment). Return ONLY the category name: \(snippet)"
        return try await aiService.processText(prompt: prompt, systemPrompt: "Return only the category name.")
    }

    struct EntityExtraction: Codable {
        let entities: [String: String]
    }

    func extractEntities(for thread: MailThread) async throws -> [String: String] {
        let content = thread.messages.last?.body ?? ""
        let schema = """
        {
          "type": "object",
          "required": ["entities"],
          "properties": {
            "entities": { "type": "object", "additionalProperties": { "type": "string" } }
          }
        }
        """
        let prompt = "Extract key entities (person, organization, date, event) from this email as JSON: \(content)"
        let json = try await aiService.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
        let result = try JSONDecoder().decode(EntityExtraction.self, from: json.data(using: .utf8)!)
        return result.entities
    }

    func detectToneRisk(for message: MailMessage) async throws -> String? {
        let prompt = "Analyze the tone of this email for any potential risk or unprofessionalism: \(message.body)"
        let analysis = try await aiService.processText(prompt: prompt, systemPrompt: "Return 'safe' or a brief description of the risk.")
        return analysis.lowercased() == "safe" ? nil : analysis
    }
}
