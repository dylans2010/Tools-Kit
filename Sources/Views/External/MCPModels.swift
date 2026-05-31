import Foundation

public enum MCPServerStatus: String, Codable {
    case connected = "Connected"
    case disconnected = "Disconnected"
    case connecting = "Connecting"
    case error = "Error"
}

public struct MCPTool: Identifiable, Codable, Hashable {
    public var id: String { name }
    public var name: String
    public var description: String
    public var parameters: [String: String] // Name: Type

    public init(name: String, description: String, parameters: [String: String] = [:]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

public struct MCPServerConfig: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var url: URL
    public var status: MCPServerStatus
    public var tools: [MCPTool]
    public var lastSeen: Date

    public init(id: UUID = UUID(), name: String, url: URL, status: MCPServerStatus = .disconnected, tools: [MCPTool] = [], lastSeen: Date = Date()) {
        self.id = id
        self.name = name
        self.url = url
        self.status = status
        self.tools = tools
        self.lastSeen = lastSeen
    }
}
