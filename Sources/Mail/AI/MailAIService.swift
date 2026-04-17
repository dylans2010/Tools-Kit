import Foundation

class MailAIService {
    static let shared = MailAIService()
    private let aiService = AIService.shared
    private let settingsManager = AIChatSettingsManager.shared

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
        Group them into: Urgent, Important, Informational.
        For each email include: sender, one-line summary, and a suggested next action.
        Keep the output concise, scannable, and action-oriented.
        Emails:
        \(context)
        """

        return try await processMailPrompt(prompt: prompt)
    }

    func priorityBrief(unreadThreads: [MailThread]) async throws -> String {
        guard !unreadThreads.isEmpty else {
            return "No unread emails were found, so there is nothing urgent to prioritize."
        }

        let threads = unreadThreads
            .sorted { $0.lastMessageDate > $1.lastMessageDate }
            .prefix(10)

        let context = threads.map { thread in
            "Subject: \(thread.subject) | From: \(thread.participants.joined(separator: ", ")) | Snippet: \(thread.snippet)"
        }.joined(separator: "\n")

        let prompt = """
        Review the unread email list and identify the 3 to 5 most important emails.
        Rank by urgency, deadlines, business impact, and requests that need a reply.
        Return a compact priority brief with these sections:
        - Top Priority
        - Next Up
        - Can Wait
        For each item include the sender, subject, why it matters, and the recommended next action.
        Emails:
        \(context)
        """

        return try await processMailPrompt(prompt: prompt)
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
