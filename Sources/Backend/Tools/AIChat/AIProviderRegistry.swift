import Foundation

// MARK: - AIProviderRegistry

final class AIProviderRegistry {
    nonisolated(unsafe) static let shared = AIProviderRegistry()

    private(set) var providers: [any AIProvider]

    private init() {
        providers = [
            OpenRouterProvider(),
            OpenAIProvider(),
            AnthropicProvider(),
            GeminiProvider(),
            MistralProvider(),
        ]
    }

    func provider(for id: String) -> (any AIProvider)? {
        providers.first { $0.id == id }
    }

    func defaultProvider() -> any AIProvider {
        providers[0]
    }
}
