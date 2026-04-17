import Foundation

class MailAIService {
    static let shared = MailAIService()
    private let aiService = AIService.shared

    func catchUp(unreadThreads: [MailThread]) async throws -> String {
        guard !unreadThreads.isEmpty else {
            return "You are all caught up. No unread emails were found."
        }

        let context = unreadThreads.map { thread in
            "From: \(thread.participants.joined(separator: ", ")), Subject: \(thread.subject), Snippet: \(thread.snippet)"
        }.joined(separator: "\n---\n")

        let prompt = """
        Summarize the following unread emails.
        Group them into: Urgent, Important, Informational.
        For each email include: sender, one-line summary, and a suggested next action.
        Keep output concise and scannable.
        Emails:
        \(context)
        """

        return try await aiService.processText(prompt: prompt, systemPrompt: "You are a workspace mail assistant.")
    }

    func summarizeThread(_ thread: MailThread) async throws -> String {
        let content = thread.messages
            .map { "\($0.from): \($0.body)" }
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
        return try await aiService.processText(prompt: prompt)
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
        return try await aiService.processText(prompt: prompt)
    }

    func improveDraft(_ draft: String, tone: String) async throws -> String {
        let prompt = "Improve the following email draft and make it sound \(tone):\n\n\(draft)"
        return try await aiService.processText(prompt: prompt)
    }
}
