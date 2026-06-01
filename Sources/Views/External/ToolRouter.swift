import Foundation

@MainActor
public final class ToolRouter: ObservableObject {
    public static let shared = ToolRouter()

    private let mcpManager = MCPManager.shared

    private init() {}

    /// Finds the best matching tool(s) for a given query and available context.
    public func route(query: String) -> [RoutedTool] {
        let allTools = mcpManager.getAllTools()
        var candidates: [RoutedTool] = []

        for (serverId, tools) in allTools {
            guard let server = mcpManager.servers.first(where: { $0.id.uuidString == serverId }) else { continue }

            for tool in tools {
                let score = calculateRelevance(query: query, tool: tool)
                if score > 0.2 { // Threshold for matching
                    candidates.append(RoutedTool(
                        server: server,
                        tool: tool,
                        relevanceScore: score
                    ))
                }
            }
        }

        // Sort by relevance score descending
        return candidates.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    /// Aggregates all tools from connected servers into a flat list with namespacing.
    public func getAvailableToolsContext() -> String {
        let connectedTools = mcpManager.getConnectedTools()
        if connectedTools.isEmpty { return "No MCP tools available." }

        var context = "## Available MCP Tools\n"
        for (serverId, tools) in connectedTools {
            guard let server = mcpManager.servers.first(where: { $0.id.uuidString == serverId }) else { continue }
            context += "### Server: \(server.name)\n"
            for tool in tools {
                // Namespacing for the AI: serverName.toolName
                let namespacedName = "\(server.name.replacingOccurrences(of: " ", with: "_")).\(tool.name)"
                context += "- **\(namespacedName)**: \(tool.description)\n"
                if let props = tool.inputSchema.properties {
                    context += "  - Parameters: \(props.keys.joined(separator: ", "))\n"
                }
            }
            context += "\n"
        }
        return context
    }

    // MARK: - Scoring Logic

    private func calculateRelevance(query: String, tool: MCPTool) -> Double {
        let queryLower = query.lowercased()
        let nameLower = tool.name.lowercased()
        let descLower = tool.description.lowercased()

        var score = 0.0

        // Keyword matching in name (high weight)
        if nameLower.contains(queryLower) || queryLower.contains(nameLower) {
            score += 0.5
        }

        // Keyword matching in description (medium weight)
        let queryWords = queryLower.components(separatedBy: .whitespacesAndNewlines)
        for word in queryWords where word.count > 3 {
            if descLower.contains(word) {
                score += 0.1
            }
        }

        // Exact match (highest weight)
        if nameLower == queryLower {
            score += 1.0
        }

        return min(score, 1.0)
    }
}

public struct RoutedTool: Identifiable {
    public var id: String { "\(server.id.uuidString).\(tool.name)" }
    public let server: MCPServer
    public let tool: MCPTool
    public let relevanceScore: Double
}
