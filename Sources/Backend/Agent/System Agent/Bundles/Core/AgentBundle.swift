import Foundation

public struct AgentBundle: Codable, Identifiable {
    public let id: String
    public let name: String
    public let version: String
    public let tools: [String]
    public let capabilities: AgentCapabilities

    public init(id: String, name: String, version: String, tools: [String], capabilities: AgentCapabilities) {
        self.id = id
        self.name = name
        self.version = version
        self.tools = tools
        self.capabilities = capabilities
    }
}
