import Foundation
import SwiftMCP

@MainActor
public final class MCPToolRegistry: ObservableObject {
    public static let shared = MCPToolRegistry()

    @Published private(set) var tools: [UUID: [MCPTool]] = [:]

    private init() {}

    public func updateTools(for serverId: UUID, tools: [MCPTool]) {
        self.tools[serverId] = tools
    }

    public func removeTools(for serverId: UUID) {
        self.tools.removeValue(forKey: serverId)
    }

    public func getAllTools() -> [RoutedTool] {
        var all: [RoutedTool] = []
        for (serverId, serverTools) in tools {
            guard let server = MCPManager.shared.servers.first(where: { $0.id == serverId }) else { continue }
            for tool in serverTools {
                all.append(RoutedTool(server: server, tool: tool, relevanceScore: 1.0))
            }
        }
        return all
    }
}
