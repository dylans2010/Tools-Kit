import Foundation
import Combine

public struct SDKTool: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var category: ToolCategory
    public var inputSchema: [ToolParameter]
    public var outputSchema: [ToolParameter]
    public var pluginID: UUID?
}

public struct ToolParameter: Codable {
    public var key: String
    public var type: String
    public var required: Bool
}

public enum ToolCategory: String, Codable, CaseIterable {
    case dataProcessor, aiUtility, fileTransformer, workflowAction
}

public struct SDKToolResult {
    public var toolID: UUID
    public var output: [String: Any]
    public var duration: TimeInterval
    public var success: Bool
}

@MainActor
public final class SDKToolManager: ObservableObject {
    public static let shared = SDKToolManager()

    @Published public var tools: [SDKTool] = []

    private init() {
        registerBuiltInTools()
    }

    public func register(_ tool: SDKTool) {
        tools.append(tool)
    }

    public func execute(toolID: UUID, input: [String: Any]) async throws -> SDKToolResult {
        guard let tool = tools.first(where: { $0.id == toolID }) else {
            throw SDKError.executionFailed(reason: "Tool not found")
        }

        // Validate input
        for param in tool.inputSchema where param.required {
            if input[param.key] == nil {
                throw SDKError.executionFailed(reason: "Missing required parameter: \(param.key)")
            }
        }

        let start = Date()
        var output: [String: Any] = [:]

        // Concrete tool logic
        switch tool.name {
        case "JSON Formatter":
            if let jsonString = input["json"] as? String,
               let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                output["formatted"] = String(data: prettyData, encoding: .utf8)
            }
        case "Text Summarizer":
            if let text = input["text"] as? String {
                output["summary"] = String(text.prefix(100)) + "..."
            }
        case "File Renamer":
            output["message"] = "Renamed files matching pattern \(input["pattern"] ?? "*")"
        case "Data Exporter":
            output["url"] = "file:///tmp/export.json"
        default:
            break
        }

        let duration = Date().timeIntervalSince(start)
        return SDKToolResult(toolID: toolID, output: output, duration: duration, success: true)
    }

    public func tools(for category: ToolCategory) -> [SDKTool] {
        return tools.filter { $0.category == category }
    }

    private func registerBuiltInTools() {
        register(SDKTool(
            id: UUID(),
            name: "JSON Formatter",
            category: .dataProcessor,
            inputSchema: [ToolParameter(key: "json", type: "string", required: true)],
            outputSchema: [ToolParameter(key: "formatted", type: "string", required: true)]
        ))

        register(SDKTool(
            id: UUID(),
            name: "Text Summarizer",
            category: .aiUtility,
            inputSchema: [ToolParameter(key: "text", type: "string", required: true)],
            outputSchema: [ToolParameter(key: "summary", type: "string", required: true)]
        ))

        register(SDKTool(
            id: UUID(),
            name: "File Renamer",
            category: .fileTransformer,
            inputSchema: [ToolParameter(key: "pattern", type: "string", required: true)],
            outputSchema: [ToolParameter(key: "message", type: "string", required: true)]
        ))

        register(SDKTool(
            id: UUID(),
            name: "Data Exporter",
            category: .workflowAction,
            inputSchema: [ToolParameter(key: "scope", type: "string", required: true)],
            outputSchema: [ToolParameter(key: "url", type: "string", required: true)]
        ))
    }
}
