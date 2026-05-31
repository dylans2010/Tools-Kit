import Foundation
import Combine

public class MCPManager: ObservableObject {
    public static let shared = MCPManager()

    @Published public var servers: [MCPServerConfig] = []

    private let storageKey = "external_mcp_servers"

    private init() {
        load()
    }

    public func addServer(name: String, url: URL) {
        let config = MCPServerConfig(name: name, url: url)
        servers.append(config)
        save()
        connect(serverID: config.id)
    }

    public func removeServer(id: UUID) {
        servers.removeAll { $0.id == id }
        save()
    }

    public func connect(serverID: UUID) {
        guard let index = servers.firstIndex(where: { $0.id == serverID }) else { return }

        servers[index].status = .connecting

        // In a real implementation, this would perform a handshake with the MCP server
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                if let idx = self.servers.firstIndex(where: { $0.id == serverID }) {
                    self.servers[idx].status = .connected
                    self.servers[idx].lastSeen = Date()
                    // Mock tools for the connected server
                    self.servers[idx].tools = [
                        MCPTool(name: "search_docs", description: "Search external documentation", parameters: ["query": "string"]),
                        MCPTool(name: "get_weather", description: "Get current weather for a location", parameters: ["location": "string"])
                    ]
                    self.save()
                }
            }
        }
    }

    public func executeTool(serverID: UUID, toolName: String, arguments: [String: Any]) async throws -> String {
        // Implementation for executing an MCP tool
        return "Executed \(toolName) on server \(serverID)"
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([MCPServerConfig].self, from: data) {
            self.servers = decoded
        }
    }
}
