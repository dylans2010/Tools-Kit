import Foundation

struct AgentCapabilityMatrix {
    private var modelCapabilities: [String: AgentCapabilities] = [:]

    init() {
        modelCapabilities["gpt-4o"] = .all
        modelCapabilities["claude-3-5-sonnet"] = .all
    }

    func capabilities(for modelId: String) -> AgentCapabilities {
        modelCapabilities[modelId] ?? .none
    }
}
