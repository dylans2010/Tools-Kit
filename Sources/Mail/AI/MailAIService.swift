import Foundation

class MailAIService {
    static let shared = MailAIService()
    private let aiService = AIService.shared

    func catchUp(unreadThreads: [MailThread]) async throws -> String {
        let context = unreadThreads.map { thread in
            "From: \(thread.participants.joined(separator: ", ")), Subject: \(thread.subject), Snippet: \(thread.snippet)"
        }.joined(separator: "\n---\n")

        let prompt = """
        Summarize the following unread emails.
        Group them into 'Urgent', 'Important', and 'Informational'.
        Emails:
        \(context)
        """

        return try await aiService.processText(prompt: prompt, systemPrompt: "You are a workspace mail assistant.")
    }

    func summarizeThread(_ thread: MailThread) async throws -> String {
        let content = thread.messages.map { "\($0.from): \($0.body)" }.joined(separator: "\n")
        let prompt = "Summarize the following email thread and extract key points:\n\n\(content)"
        return try await aiService.processText(prompt: prompt)
    }

    func generateReply(for message: MailMessage, context: String) async throws -> String {
        let prompt = "Generate a reply to the following email: '\(message.body)'. Additional context for the reply: \(context)"
        return try await aiService.processText(prompt: prompt)
    }

    func improveDraft(_ draft: String, tone: String) async throws -> String {
        let prompt = "Improve the following email draft and make it sound \(tone):\n\n\(draft)"
        return try await aiService.processText(prompt: prompt)
    }
}
