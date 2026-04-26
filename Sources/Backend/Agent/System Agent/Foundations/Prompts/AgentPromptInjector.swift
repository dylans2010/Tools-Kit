import Foundation

struct AgentPromptInjector {
    func inject(system: String, into userPrompt: String) -> String {
        "\(system)

\(userPrompt)"
    }
}
