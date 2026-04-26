import Foundation

public struct AgentCapabilityMatrix {
    private var modelCapabilities: [String: AgentCapabilities] = [:]

    public init() {
        modelCapabilities["gpt-4o"] = .all
        modelCapabilities["claude-3-5-sonnet"] = .all
    }

    public func capabilities(for modelId: String) -> AgentCapabilities {
        modelCapabilities[modelId] ?? .none
    }
}
