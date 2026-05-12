import Foundation

struct AgentPromptInjector: Sendable {
    init() {}

    func inject(prompt: String, into systemPrompt: String) -> String {
        "\(systemPrompt)\n\nAdditional Instructions:\n\(prompt)"
    }
}
