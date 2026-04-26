import Foundation

struct SystemAgentToolDefinition: Codable {
    let name: String
    let description: String
    let inputSchema: [String: AnyCodable]
}

final class SystemAgentToolRouter {
    let toolDefinitions: [SystemAgentToolDefinition]

    private let registry: AgentSystemTools

    init(registry: AgentSystemTools = .shared) {
        self.registry = registry
        self.toolDefinitions = SystemAgentToolRouter.buildDefinitions(registry: registry)
    }

    func route(toolName: String, input: [String: Any]) async throws -> String {
        guard registry.exists(toolName) else {
            throw SystemAgentError.unknownTool(name: toolName)
        }

        let context = SystemToolContext(
            workspaceId: "local_workspace",
            sessionId: UUID().uuidString,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        do {
            let response = try await registry.execute(name: toolName, input: input, context: context)
            let data = try JSONEncoder().encode(response)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            throw SystemAgentError.toolExecutionFailure(tool: toolName, underlying: error)
        }
    }

    private static func buildDefinitions(registry: AgentSystemTools) -> [SystemAgentToolDefinition] {
        let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/Backend/Agent/SystemTools")

        let files = ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "swift" }

        let sourceByToolName: [String: String] = files.reduce(into: [:]) { result, url in
            guard let contents = try? String(contentsOf: url) else { return }
            if let toolName = extractToolName(from: contents) {
                result[toolName] = contents
            }
        }

        return registry.listAvailableTools().compactMap { toolName in
            guard let source = sourceByToolName[toolName] else { return nil }
            let keys = extractInputKeys(from: source)
            let schema: [String: Any] = [
                "type": "object",
                "properties": keys.reduce(into: [String: Any]()) { partialResult, key in
                    partialResult[key] = ["type": ["string", "number", "boolean", "object", "array", "null"]]
                },
                "required": []
            ]
            return SystemAgentToolDefinition(
                name: toolName,
                description: "System tool \(toolName)",
                inputSchema: schema.mapValues(AnyCodable.init)
            )
        }
    }

    private static func extractToolName(from source: String) -> String? {
        let pattern = #"let\s+name\s*=\s*\"([^\"]+)\""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, options: [], range: range),
              let nameRange = Range(match.range(at: 1), in: source) else { return nil }
        return String(source[nameRange])
    }

    private static func extractInputKeys(from source: String) -> [String] {
        let pattern = #"input\[\"([^\"]+)\"\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        let matches = regex.matches(in: source, options: [], range: range)
        let keys = matches.compactMap { match -> String? in
            guard let keyRange = Range(match.range(at: 1), in: source) else { return nil }
            return String(source[keyRange])
        }
        return Array(Set(keys)).sorted()
    }
}
