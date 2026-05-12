import Foundation

protocol KeyboardAIFrameworkProtocol {
    func analyze(text: String) async -> TextAnalysis
    func rewrite(text: String, style: RewriteStyle) async -> String
    func generateSuggestions(text: String) async -> [Suggestion]
    func generateReplies(text: String) async -> [String]
    func convert(text: String, to type: ConversionType) async -> String
}

class KeyboardAIFramework: KeyboardAIFrameworkProtocol {
    private let contextAnalyzer = ContextAnalyzer()
    private let rewriteEngine = RewriteEngine()
    private let suggestionEngine = SuggestionEngine()
    private let localEngine = LocalEngine()

    private let aiGateway = KeyboardAIGateway()

    func analyze(text: String) async -> TextAnalysis {
        return contextAnalyzer.analyze(text: text)
    }

    func rewrite(text: String, style: RewriteStyle) async -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return text }

        let localRewrite = rewriteEngine.rewrite(text: text, style: style)
        let prompt = """
        Rewrite the user text in the requested style while preserving meaning.
        Return only the rewritten text, with no quotes and no markdown.

        Style: \(style.rawValue)
        Text: \(text)
        """

        guard let remoteRewrite = await aiGateway.generateText(prompt: prompt), !remoteRewrite.isEmpty else {
            return localRewrite
        }

        return remoteRewrite
    }

    func generateSuggestions(text: String) async -> [Suggestion] {
        let analysis = contextAnalyzer.analyze(text: text)
        var suggestions = suggestionEngine.generateSuggestions(text: text, analysis: analysis)

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return suggestions
        }

        let prompt = """
        Provide up to 3 concise writing improvements for the user text.
        Return JSON array only in this format:
        [{"suggestedText":"...","category":"Grammar|Clarity|Tone|Rewrite|Smart Reply","score":0.0}]

        Text: \(text)
        """

        if let remoteSuggestions = await aiGateway.generateSuggestions(from: prompt, originalText: text) {
            suggestions.append(contentsOf: remoteSuggestions)
        }

        let deduped = Dictionary(grouping: suggestions, by: { $0.suggestedText.lowercased() }).compactMap { $0.value.first }
        return Array(deduped.sorted(by: { $0.score > $1.score }).prefix(3))
    }

    func generateReplies(text: String) async -> [String] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ["Sounds good!", "Thanks for the update.", "Got it."]
        }

        let prompt = """
        Generate 3 short contextual replies.
        Return JSON array of strings only.

        Message:\n\(text)
        """

        if let replies = await aiGateway.generateReplies(from: prompt), !replies.isEmpty {
            return Array(replies.prefix(3))
        }

        return [
            "Sounds good, thanks!",
            "I'll look into it.",
            "Can we discuss this later?"
        ]
    }

    func convert(text: String, to type: ConversionType) async -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return text }

        let local = convertLocally(text: text, to: type)
        let prompt = """
        Convert the user text to the requested output format.
        Return only converted text.

        Target: \(type.rawValue)
        Text: \(text)
        """

        guard let remote = await aiGateway.generateText(prompt: prompt), !remote.isEmpty else {
            return local
        }

        return remote
    }

    func processLocal(text: String) -> AIResponse {
        return localEngine.processLocally(text: text)
    }

    private func convertLocally(text: String, to type: ConversionType) -> String {
        switch type {
        case .email:
            return "Dear Team,\n\n" + text + "\n\nBest regards,\nUser"
        case .message:
            return "Hey: " + text
        case .task:
            return "- [ ] " + text
        case .note:
            return "Summary: " + text
        case .list:
            return text.components(separatedBy: ". ").map { "* " + $0 }.joined(separator: "\n")
        }
    }
}

private final class KeyboardAIGateway {
    private enum Keys: Sendable {
        static let openRouterKey = "openrouter_api_key"
        static let openAIKey = "openai_api_key"
        static let provider = "keyboard_ai_provider"
        static let appGroup = "group.com.toolskit.shared"
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateText(prompt: String) async -> String? {
        if let provider = resolveProvider() {
            do {
                return try await provider.send(prompt: prompt, session: session)
            } catch {
                return nil
            }
        }
        return nil
    }

    func generateSuggestions(from prompt: String, originalText: String) async -> [Suggestion]? {
        guard let raw = await generateText(prompt: prompt) else { return nil }
        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SuggestionPayload].self, from: data) else {
            return nil
        }

        return decoded.prefix(3).map {
            Suggestion(
                originalText: originalText,
                suggestedText: $0.suggestedText,
                category: $0.suggestionCategory,
                score: min(max($0.score, 0), 1)
            )
        }
    }

    func generateReplies(from prompt: String) async -> [String]? {
        guard let raw = await generateText(prompt: prompt) else { return nil }
        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return decoded
    }

    private func resolveProvider() -> AIProviderClient? {
        let defaults = UserDefaults.standard
        let sharedDefaults = UserDefaults(suiteName: Keys.appGroup)
        let provider = (sharedDefaults?.string(forKey: Keys.provider) ?? defaults.string(forKey: Keys.provider) ?? "openrouter").lowercased()

        if provider == "openai", let key = readKey(named: Keys.openAIKey) {
            return OpenAIClient(apiKey: key)
        }

        if let key = readKey(named: Keys.openRouterKey) {
            return OpenRouterClient(apiKey: key)
        }

        return nil
    }

    private func readKey(named key: String) -> String? {
        let defaults = UserDefaults.standard
        let sharedDefaults = UserDefaults(suiteName: Keys.appGroup)
        return sharedDefaults?.string(forKey: key) ?? defaults.string(forKey: key)
    }
}

private protocol AIProviderClient {
    func send(prompt: String, session: URLSession) async throws -> String
}

private struct OpenRouterClient: AIProviderClient, Sendable {
    let apiKey: String

    func send(prompt: String, session: URLSession) async throws -> String {
        var request = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "model": "openai/gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a concise keyboard writing assistant."],
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return parseChatCompletion(data: data)
    }
}

private struct OpenAIClient: AIProviderClient, Sendable {
    let apiKey: String

    func send(prompt: String, session: URLSession) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a concise keyboard writing assistant."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.4
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return parseChatCompletion(data: data)
    }
}

private struct SuggestionPayload: Codable, Sendable {
    let suggestedText: String
    let category: String
    let score: Double

    var suggestionCategory: SuggestionCategory {
        switch category.lowercased() {
        case "grammar": return .grammar
        case "clarity": return .clarity
        case "tone": return .tone
        case "smart reply", "reply": return .reply
        default: return .rewrite
        }
    }
}

private func parseChatCompletion(data: Data) -> String {
    guard
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let choices = object["choices"] as? [[String: Any]],
        let message = choices.first?["message"] as? [String: Any],
        let content = message["content"] as? String
    else {
        return ""
    }

    return content
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
