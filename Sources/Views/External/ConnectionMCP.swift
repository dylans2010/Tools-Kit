import Foundation
import SwiftUI
import Combine

@MainActor
public final class MCPPersonaBridge: ObservableObject {
    private let mcpManager = MCPManager.shared
    private let toolRouter = ToolRouter.shared

    public init() {}

    public func execute(
        serverName: String,
        toolName: String,
        arguments: [String: Any],
        purpose: String
    ) async throws -> String {
        guard let server = mcpManager.servers.first(where: { $0.name.lowercased() == serverName.lowercased() || $0.name.replacingOccurrences(of: " ", with: "_").lowercased() == serverName.lowercased() }) else {
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

    public func connectedServersContext() -> String {
        return toolRouter.getAvailableToolsContext()
    }
}

public struct MCPCallExtract {
    public let serverName: String
    public let toolName: String
    public let arguments: [String: Any]
    public let purpose: String
}

public struct MCPToolCallParser {
    public static func extractMCPCalls(from text: String) -> [MCPCallExtract] {
        var calls: [MCPCallExtract] = []
        // Using a non-greedy regex to support multiple calls properly
        let pattern = #"\[MCP_CALL:\s*server="([^"]+)",\s*tool="([^"]+)",\s*arguments=(\{.*?\}),\s*purpose="([^"]+)"\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }

        let nsRange = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        for match in matches {
            let serverName = (text as NSString).substring(with: match.range(at: 1))
            let toolName = (text as NSString).substring(with: match.range(at: 2))
            let argsStr = (text as NSString).substring(with: match.range(at: 3))
            let purpose = (text as NSString).substring(with: match.range(at: 4))

            if let data = argsStr.data(using: .utf8),
               let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                calls.append(MCPCallExtract(serverName: serverName, toolName: toolName, arguments: args, purpose: purpose))
            }
        }
        return calls
    }
}
