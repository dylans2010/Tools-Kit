import Foundation

struct AgentBundle: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let version: String
    let tools: [String]
    let capabilities: AgentCapabilities

    init(id: String, name: String, version: String, tools: [String], capabilities: AgentCapabilities) {
        self.id = id
        self.name = name
        self.version = version
        self.tools = tools
        self.capabilities = capabilities
    }
}
