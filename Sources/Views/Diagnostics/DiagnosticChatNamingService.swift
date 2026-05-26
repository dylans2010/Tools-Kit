import Foundation

final class DiagnosticChatNamingService {
    static let shared = DiagnosticChatNamingService()
    private let aiService = AIService.shared

    func suggestTitle(for messages: [ChatMessage]) async -> String? {
        guard !messages.isEmpty else { return nil }

        let chatContext = messages.prefix(10).map { "\($0.role): \($0.content)" }.joined(separator: "\n")

        let prompt = """
        Based on the following iOS diagnostic chat conversation, suggest a concise and professional title for this session.
        The title MUST be under 50 characters.
        Do NOT use quotes in the title.
        ONLY return the title text.

        Conversation:
        \(chatContext)
        """

        do {
            let title = try await aiService.processText(
                prompt: prompt,
                systemPrompt: "You are a concise titling assistant for a technical diagnostic app."
            )

            let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")

            return String(cleanedTitle.prefix(50))
        } catch {
            print("Failed to name chat: \(error)")
            return nil
        }
    }
}
