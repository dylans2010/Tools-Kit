import Foundation
import SwiftUI
import Combine

@MainActor
final class MCPPersonaBridge: ObservableObject {
    private let mcpManager = MCPManager.shared

    // The Anthropic tool definition Persona exposes to the LLM
    static let toolDefinition: [String: Any] = [
        "name": "connect_to_mcp",
        "description": """
        Execute a tool on a connected MCP (Model Context Protocol) server. Use this when you need to
        interact with external services, APIs, databases, or automation tools that the user has connected.
        Always check which servers are available before calling. You must specify the exact tool name as
        discovered from the server. Arguments must match the tool's input schema.
        """,
        "input_schema": [
            "type": "object",
            "properties": [
                "server_name": [
                    "type": "string",
                    "description": "The name of the MCP server to use, exactly as shown in the user's connected servers list."
                ],
                "tool_name": [
                    "type": "string",
                    "description": "The exact name of the tool to call on that server, as returned by tools/list."
                ],
                "arguments": [
                    "type": "object",
                    "description": "Key-value arguments to pass to the tool. Must conform to the tool's inputSchema."
                ],
                "purpose": [
                    "type": "string",
                    "description": "A short human-readable explanation of why you are calling this tool, shown to the user."
                ]
            ],
            "required": ["server_name", "tool_name", "purpose"]
        ]
    ]

    func execute(
        serverName: String,
        toolName: String,
        arguments: [String: Any],
        purpose: String
    ) async throws -> String {
        guard let server = mcpManager.servers.first(where: { $0.name.lowercased() == serverName.lowercased() }) else {
            let available = mcpManager.servers.map { $0.name }.joined(separator: ", ")
            throw MCPError.toolNotFound("No connected server named '\(serverName)'. Available: \(available)")
        }

        let result = try await mcpManager.callTool(
            named: toolName,
            on: server,
            arguments: arguments,
            purpose: purpose
        )

        return "[MCP: \(server.name) → \(toolName)]\n\(result)"
    }

    func connectedServersContext() -> String {
        let connectedServers = mcpManager.servers.filter { $0.connectionStatus == .connected }
        if connectedServers.isEmpty { return "" }

        var context = "## Connected MCP Servers\n"
        for server in connectedServers {
            context += "### \(server.name) (\(server.baseURL))\n"
            if server.discoveredTools.isEmpty {
                context += "- No tools discovered yet.\n"
            } else {
                for tool in server.discoveredTools {
                    context += "- **\(tool.name)**: \(tool.description)\n"
                }
            }
            context += "\n"
        }
        return context
    }
}

struct MCPToolCallParser {
    static func parseArguments(_ raw: Any?) -> [String: Any] {
        guard let dict = raw as? [String: Any] else { return [:] }
        return dict
    }

    static func extractMCPCall(from content: [[String: Any]]) -> MCPCallExtract? {
        for block in content {
            if let type = block["type"] as? String, type == "tool_use",
               let name = block["name"] as? String, name == "connect_to_mcp",
               let input = block["input"] as? [String: Any],
               let id = block["id"] as? String {

                return MCPCallExtract(
                    serverName: input["server_name"] as? String ?? "",
                    toolName: input["tool_name"] as? String ?? "",
                    arguments: input["arguments"] as? [String: Any] ?? [:],
                    purpose: input["purpose"] as? String ?? "Executing external tool",
                    toolUseId: id
                )
            }
        }
        return nil
    }
}

struct MCPCallExtract {
    let serverName: String
    let toolName: String
    let arguments: [String: Any]
    let purpose: String
    let toolUseId: String
}
