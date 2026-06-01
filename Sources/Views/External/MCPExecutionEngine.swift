import Foundation

@MainActor
public final class MCPExecutionEngine {
    public static let shared = MCPExecutionEngine()

    private let mcpManager = MCPManager.shared
    private let toolRouter = ToolRouter.shared

    private init() {}

    public func execute(
        serverName: String,
        toolName: String,
        arguments: [String: Any],
        purpose: String
    ) async throws -> String {
        // 1. Resolve Server
        guard let server = mcpManager.servers.first(where: {
            $0.name.lowercased() == serverName.lowercased() ||
            $0.name.replacingOccurrences(of: " ", with: "_").lowercased() == serverName.lowercased()
        }) else {
            throw MCPError.toolNotFound("Server '\(serverName)' not found.")
        }

        // 2. Validate Tool Existence
        let tools = mcpManager.toolRegistry[server.id.uuidString] ?? []
        guard tools.contains(where: { $0.name == toolName }) else {
            throw MCPError.toolNotFound("Tool '\(toolName)' not found on server '\(serverName)'.")
        }

        // 3. Orchestrate Execution
        let result = try await mcpManager.callTool(
            named: toolName,
            on: server,
            arguments: arguments,
            purpose: purpose
        )

        return result
    }

    public func processAIResponse(_ response: String) async -> [MCPToolInvocationResult] {
        let calls = MCPToolCallParser.extractMCPCalls(from: response)
        var results: [MCPToolInvocationResult] = []

        for call in calls {
            do {
                let output = try await execute(
                    serverName: call.serverName,
                    toolName: call.toolName,
                    arguments: call.arguments,
                    purpose: call.purpose
                )
                results.append(.success(toolName: call.toolName, output: output))
            } catch {
                results.append(.failure(toolName: call.toolName, error: error.localizedDescription))
            }
        }

        return results
    }
}

public enum MCPToolInvocationResult {
    case success(toolName: String, output: String)
    case failure(toolName: String, error: String)

    public var summary: String {
        switch self {
        case .success(let name, let output):
            return "Tool '\(name)' completed successfully: \(output)"
        case .failure(let name, let error):
            return "Tool '\(name)' failed: \(error)"
        }
    }
}
