import Foundation

struct AgentPromptLibrary {
    private(set) var prompts: [String: AgentSystemPrompt] = [:]

    mutating func set(_ prompt: AgentSystemPrompt, named name: String) {
        prompts[name] = prompt
    }

    func prompt(named name: String) -> AgentSystemPrompt? { prompts[name] }
}
