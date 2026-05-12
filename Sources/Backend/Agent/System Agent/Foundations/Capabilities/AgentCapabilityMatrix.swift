import Foundation

struct AgentCapabilityMatrix: Sendable {
    private var modelCapabilities: [String: AgentCapabilities] = [:]

    init() {
        modelCapabilities["gpt-4o"] = .all
        modelCapabilities["claude-3-5-sonnet"] = .all
    }

    func capabilities(for modelId: String) -> AgentCapabilities {
        modelCapabilities[modelId] ?? .none
    }
}
