import Foundation

enum AIError: Error {
    case missingAPIKey
    case networkError(String)
    case invalidResponse
}

class AIService {
    private let openRouter = OpenRouterService()

    func processText(prompt: String, systemPrompt: String = "You are a helpful assistant.", model: String = "google/gemini-2.0-flash-exp:free") async throws -> String {
        guard let apiKey = APIKeyManager.shared.getKey() else {
            throw AIError.missingAPIKey
        }

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: prompt)
        ]

        return try await openRouter.sendMessage(messages: messages, apiKey: apiKey, model: model)
    }

    func summarize(text: String) async throws -> String {
        let prompt = "Summarize the following text, providing key points and action items:\n\n\(text)"
        return try await processText(prompt: prompt)
    }

    func debugCode(code: String) async throws -> String {
        let prompt = "Analyze the following code for bugs, logic errors, and optimization opportunities. Return structured suggestions:\n\n\(code)"
        return try await processText(prompt: prompt, systemPrompt: "You are an expert software engineer.")
    }

    func generateReminders(topic: String) async throws -> String {
        let prompt = "Generate a list of reminders for: \(topic). Extract intent, date, time, and priority where possible."
        return try await processText(prompt: prompt)
    }

    func autofill(context: String, field: String) async throws -> String {
        let prompt = "Based on the context: \"\(context)\", what should be the value for the field: \"\(field)\"?"
        return try await processText(prompt: prompt)
    }

    func reason(problem: String) async throws -> String {
        let prompt = "Solve this problem step-by-step with clear reasoning:\n\n\(problem)"
        return try await processText(prompt: prompt)
    }
}
