import Foundation

struct SystemAgentCapabilityProfile: Codable {
    var name: String
    var capabilities: AgentCapabilities

    init(name: String = "system", capabilities: AgentCapabilities = [.tools, .planning, .streaming]) {
        self.name = name
        self.capabilities = capabilities
    }

    func supports(_ capability: AgentCapabilities) -> Bool {
        capabilities.contains(capability)
    }
}
