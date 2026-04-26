import Foundation

struct JulesAgentCapabilityProfile: Codable {
    var persona: String
    var capabilities: AgentCapabilities

    init(persona: String = "Jules", capabilities: AgentCapabilities = [.codeGeneration, .planning, .memory]) {
        self.persona = persona
        self.capabilities = capabilities
    }
}
