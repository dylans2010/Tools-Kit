import Foundation

enum AIError: Error {
    case missingAPIKey
    case networkError(String)
    case invalidResponse
    case unknownProvider(String)
}

class AIService {
    private let registry = AIProviderRegistry.shared
    private let keyManager = APIKeyManager.shared
    private let settingsManager = AIChatSettingsManager.shared

    // MARK: - Current provider helpers

    private var currentProviderID: String {
        settingsManager.settings.selectedProviderID
    }

    private var currentProvider: (any AIProvider)? {
        registry.provider(for: currentProviderID)
    }

    private var currentAPIKey: String? {
        keyManager.getKey(for: currentProviderID)
    }

    // MARK: - Public API

    func processText(prompt: String, systemPrompt: String = "You are a helpful assistant.", model: String? = nil) async throws -> String {
        guard let provider = currentProvider else {
            throw AIError.unknownProvider(currentProviderID)
        }
        guard let apiKey = currentAPIKey else {
            throw AIError.missingAPIKey
        }

        let modelToUse = model ?? settingsManager.settings.modelID
        let systemPromptToUse = systemPrompt.isEmpty ? settingsManager.settings.systemPrompt : systemPrompt

        let messages = [
            ChatMessage(role: "system", content: systemPromptToUse),
            ChatMessage(role: "user", content: prompt)
        ]

        return try await provider.send(messages: messages, model: modelToUse, apiKey: apiKey)
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
