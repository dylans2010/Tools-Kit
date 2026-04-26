import Foundation

struct AgentCapabilityMatrix {
    private(set) var rows: [String: AgentCapabilities] = [:]

    mutating func set(_ capabilities: AgentCapabilities, for profile: String) {
        rows[profile] = capabilities
    }

    func capabilities(for profile: String) -> AgentCapabilities {
        rows[profile] ?? []
    }
}
