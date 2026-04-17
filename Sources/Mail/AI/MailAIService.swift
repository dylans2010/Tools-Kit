import Foundation

class MailAIService {
    static let shared = MailAIService()
    private let aiService = AIService.shared
    private let settingsManager = AIChatSettingsManager.shared

    struct PriorityDigest {
        let summaryMarkdown: String
        let priorityThreadIDs: [String]
    }

    private struct PriorityDigestResponse: Decodable {
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
        systemPrompt: String = "You are a workspace mail assistant."
    ) async throws -> String {
        try await aiService.processText(
            prompt: prompt,
            systemPrompt: systemPrompt,
            model: await preferredModelID()
        )
    }

    private func decodePriorityDigest(from raw: String) -> PriorityDigestResponse? {
        let stripped = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let start = stripped.firstIndex(of: "{")
        let end = stripped.lastIndex(of: "}")
        guard let start, let end, start <= end else { return nil }

        let jsonString = String(stripped[start...end])
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PriorityDigestResponse.self, from: data)
    }

    func catchUp(unreadThreads: [MailThread]) async throws -> String {
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

        let prompt = """
        Analyze every email below and identify only the priority emails.
        A priority email is urgent, deadline-driven, high business impact, or blocked waiting for a reply.
        Return JSON only with this exact shape:
        {
          "summary_markdown": "short markdown summary of priority emails only",
          "priority_thread_ids": ["thread-id-1", "thread-id-2"]
        }
        Rules:
        - Include 1 to 7 IDs in priority_thread_ids.
        - summary_markdown must include only priority content, no non-priority categories.
        - Keep summary_markdown under 120 words.
        Emails:
        \(context)
        """

        let raw = try await processMailPrompt(
            prompt: prompt,
            systemPrompt: "You are a strict email triage assistant that returns exact JSON and focuses only on priority email analysis."
        )

        if let decoded = decodePriorityDigest(from: raw) {
            return PriorityDigest(
                summaryMarkdown: decoded.summary_markdown,
                priorityThreadIDs: decoded.priority_thread_ids
            )
        }

        let fallback = Array(threads.prefix(3))
        let fallbackSummary = fallback.enumerated().map { index, thread in
            let sender = thread.participants.first ?? "Unknown"
            return "- **\(index + 1). \(thread.subject)** from \(sender)"
        }.joined(separator: "\n")

        return PriorityDigest(
            summaryMarkdown: "### Priority Emails\n\(fallbackSummary)",
            priorityThreadIDs: fallback.map(\.id)
        )
    }

    func priorityBrief(unreadThreads: [MailThread]) async throws -> String {
        try await priorityDigest(unreadThreads: unreadThreads).summaryMarkdown
    }

    func summarizeThread(_ thread: MailThread) async throws -> String {
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
        guard !messageBody.isEmpty else {
            return "Thanks for your email. Could you share a bit more detail so I can respond accurately?"
        }

        let prompt = """
        Write a clear, professional reply to this email.
        Original email:
        \(messageBody)

        Additional context for the reply:
        \(context)
        """
        return try await processMailPrompt(prompt: prompt, systemPrompt: "You are an expert email assistant. Write clear, helpful, and professional replies.")
    }

    func improveDraft(_ draft: String, tone: String) async throws -> String {
        let prompt = """
        Improve the following email draft and make it sound \(tone).
        Preserve the intent, keep the wording natural, and avoid adding unsupported details.

        Draft:
        \(draft)
        """
        return try await processMailPrompt(prompt: prompt, systemPrompt: "You are a highly capable email writing assistant.")
    }

    func composeEmail(prompt: String, systemPrompt: String = "You are a highly capable email writing assistant.") async throws -> String {
        try await processMailPrompt(prompt: prompt, systemPrompt: systemPrompt)
    }
}
