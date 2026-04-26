import Foundation

public struct AgentPromptInjector {
    public init() {}

    public func inject(prompt: String, into systemPrompt: String) -> String {
        "\(systemPrompt)\n\nAdditional Instructions:\n\(prompt)"
    }
}
