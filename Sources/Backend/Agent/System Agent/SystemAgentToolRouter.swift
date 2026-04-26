import Foundation

struct SystemAgentToolDefinition: Codable {
    let name: String
    let description: String
    let inputSchema: [String: AnyCodable]
}

private struct ToolParameterSpec {
    let name: String
    let typeDescription: String
    let isRequired: Bool
}

final class SystemAgentToolRouter {
    let toolDefinitions: [SystemAgentToolDefinition]
    private let parameterSpecsByTool: [String: [ToolParameterSpec]]

    private let registry: AgentSystemTools

    init(registry: AgentSystemTools = .shared) {
        self.registry = registry
        let metadata = SystemAgentToolRouter.loadToolMetadata(registry: registry)
        self.parameterSpecsByTool = metadata.reduce(into: [:]) { partialResult, item in
            partialResult[item.name] = item.parameters
        }
        self.toolDefinitions = metadata.map { definition in
            SystemAgentToolDefinition(name: definition.name, description: definition.description, inputSchema: definition.inputSchema)
        }
    }

    func route(toolName: String, input: [String: Any]) async throws -> String {
        guard registry.exists(toolName) else {
            throw SystemAgentError.unknownTool(name: toolName)
        }
        try validateInput(for: toolName, input: input)

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

    private struct ToolMetadata {
        let name: String
        let description: String
        let inputSchema: [String: AnyCodable]
        let parameters: [ToolParameterSpec]
    }

    private func validateInput(for toolName: String, input: [String: Any]) throws {
        guard let specs = parameterSpecsByTool[toolName] else { return }
        for spec in specs where spec.isRequired {
            guard input[spec.name] != nil else {
                let error = SystemToolError.missingParameter(spec.name)
                throw SystemAgentError.toolExecutionFailure(tool: toolName, underlying: error)
            }
        }
        for spec in specs {
            guard let value = input[spec.name] else { continue }
            guard matches(expectedType: spec.typeDescription, value: value) else {
                let error = SystemToolError(
                    message: "Parameter '\(spec.name)' must be \(spec.typeDescription)",
                    code: "invalid_parameter_type"
                )
                throw SystemAgentError.toolExecutionFailure(tool: toolName, underlying: error)
            }
        }
    }

    private func matches(expectedType: String, value: Any) -> Bool {
        switch expectedType {
        case "String":
            return value is String
        case "Int":
            return value is Int
        case "Double":
            return value is Double || value is Int
        case "Bool":
            return value is Bool
        case "[String]":
            return value is [String]
        case "[Any]":
            return value is [Any]
        case "[String: Any]":
            return value is [String: Any]
        default:
            return true
        }
    }

    private static func loadToolMetadata(registry: AgentSystemTools) -> [ToolMetadata] {
        let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/Backend/Agent/SystemTools")

        let files = ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "swift" }

        let metadataByToolName: [String: (description: String, parameters: [ToolParameterSpec])] = files.reduce(into: [:]) { result, url in
            guard let contents = try? String(contentsOf: url) else { return }
            if let toolName = extractToolName(from: contents) {
                result[toolName] = (description: extractDescription(from: contents, fallbackToolName: toolName), parameters: extractParameters(from: contents))
            }
        }

        return registry.listAvailableTools().compactMap { toolName in
            guard let metadata = metadataByToolName[toolName] else { return nil }
            let properties = metadata.parameters.reduce(into: [String: Any]()) { partialResult, parameter in
                partialResult[parameter.name] = [
                    "type": jsonSchemaType(for: parameter.typeDescription),
                    "description": "\(parameter.typeDescription)\(parameter.isRequired ? " (required)" : " (optional)")"
                ]
            }
            let schema: [String: Any] = [
                "type": "object",
                "properties": properties,
                "required": metadata.parameters.filter(\.isRequired).map(\.name)
            ]
            return ToolMetadata(
                name: toolName,
                description: metadata.description,
                inputSchema: schema.mapValues(AnyCodable.init),
                parameters: metadata.parameters
            )
        }
    }

    private static func extractDescription(from source: String, fallbackToolName: String) -> String {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        if let classLine = lines.first(where: { $0.contains("final class") || $0.contains("struct") }),
           let commentLineIndex = lines.firstIndex(where: { $0 == classLine }),
           commentLineIndex > lines.startIndex {
            let previous = lines[lines.index(before: commentLineIndex)].trimmingCharacters(in: .whitespaces)
            if previous.hasPrefix("///") {
                return previous.replacingOccurrences(of: "///", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        return "System tool: \(fallbackToolName)"
    }

    private static func extractToolName(from source: String) -> String? {
        let pattern = #"let\s+name\s*=\s*\"([^\"]+)\""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, options: [], range: range),
              let nameRange = Range(match.range(at: 1), in: source) else { return nil }
        return String(source[nameRange])
    }

    private static func extractParameters(from source: String) -> [ToolParameterSpec] {
        let guardedPattern = #"guard\s+let\s+\w+\s*=\s*input\["([^"]+)"\]\s+as\?\s*([^\s,]+)"#
        let requiredStringPattern = #"requireString\(\s*input\s*,\s*key:\s*"([^"]+)"\s*\)"#
        let optionalPattern = #"input\["([^"]+)"\]\s+as\?\s*([^\s,\)\?]+)"#

        guard let guardedRegex = try? NSRegularExpression(pattern: guardedPattern),
              let requiredStringRegex = try? NSRegularExpression(pattern: requiredStringPattern),
              let optionalRegex = try? NSRegularExpression(pattern: optionalPattern) else {
            return []
        }

        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        var parametersByName: [String: ToolParameterSpec] = [:]

        for match in guardedRegex.matches(in: source, options: [], range: range) {
            guard let keyRange = Range(match.range(at: 1), in: source),
                  let typeRange = Range(match.range(at: 2), in: source) else { continue }
            let key = String(source[keyRange])
            let type = normalize(typeToken: String(source[typeRange]))
            parametersByName[key] = ToolParameterSpec(name: key, typeDescription: type, isRequired: true)
        }

        for match in requiredStringRegex.matches(in: source, options: [], range: range) {
            guard let keyRange = Range(match.range(at: 1), in: source) else { continue }
            let key = String(source[keyRange])
            parametersByName[key] = ToolParameterSpec(name: key, typeDescription: "String", isRequired: true)
        }

        for match in optionalRegex.matches(in: source, options: [], range: range) {
            guard let keyRange = Range(match.range(at: 1), in: source),
                  let typeRange = Range(match.range(at: 2), in: source) else { continue }
            let key = String(source[keyRange])
            let type = normalize(typeToken: String(source[typeRange]))
            if parametersByName[key] == nil {
                parametersByName[key] = ToolParameterSpec(name: key, typeDescription: type, isRequired: false)
            }
        }
        return parametersByName.values.sorted { $0.name < $1.name }
    }

    private static func normalize(typeToken: String) -> String {
        if typeToken.hasPrefix("[String:") {
            return "[String: Any]"
        }
        if typeToken.hasPrefix("[String]") {
            return "[String]"
        }
        if typeToken.hasPrefix("[") {
            return "[Any]"
        }
        return typeToken
    }

    private static func jsonSchemaType(for type: String) -> Any {
        switch type {
        case "String":
            return "string"
        case "Int":
            return "integer"
        case "Double":
            return "number"
        case "Bool":
            return "boolean"
        case "[String]", "[Any]":
            return "array"
        case "[String: Any]":
            return "object"
        default:
            return ["string", "number", "boolean", "object", "array", "null"]
        }
    }
}
