import Foundation

public struct ToolParameter: Codable {
    public var key: String
    public var type: String
    public var required: Bool

    public init(key: String, type: String, required: Bool) {
        self.key = key
        self.type = type
        self.required = required
    }
}

public enum ToolCategory: String, Codable, CaseIterable {
    case dataProcessor, aiUtility, fileTransformer, workflowAction
}

public struct SDKTool: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var category: ToolCategory
    public var inputSchema: [ToolParameter]
    public var outputSchema: [ToolParameter]
    public var pluginID: UUID?

    public init(id: UUID = UUID(), name: String, category: ToolCategory, inputSchema: [ToolParameter] = [], outputSchema: [ToolParameter] = [], pluginID: UUID? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
        self.pluginID = pluginID
    }
}

public struct SDKToolResult {
    public var toolID: UUID
    public var output: [String: Any]
    public var duration: TimeInterval
    public var success: Bool
}

public enum SDKToolError: Error, LocalizedError {
    case missingParameter(key: String)
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingParameter(let key): return "Missing required parameter: \(key)"
        case .executionFailed(let msg): return "Tool execution failed: \(msg)"
        }
    }
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
            throw SDKToolError.executionFailed("Tool not found")
        }

        // Validate input
        for param in tool.inputSchema where param.required {
            if input[param.key] == nil {
                throw SDKToolError.missingParameter(key: param.key)
            }
        }

        let start = Date()
        var output: [String: Any] = [:]

        // Built-in tools execution logic
        switch tool.name {
        case "JSON Formatter":
            if let json = input["json"] as? String,
               let data = json.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                output["formatted"] = prettyString
            }
        case "Text Summarizer":
            if let text = input["text"] as? String {
                output["summary"] = String(text.prefix(100)) + "..."
            }
        case "File Renamer":
            output["status"] = "Renamed"
        case "Data Exporter":
            output["url"] = "file://tmp/export.json"
        default:
            break
        }

        return SDKToolResult(
            toolID: toolID,
            output: output,
            duration: Date().timeIntervalSince(start),
            success: true
        )
    }

    public func tools(for category: ToolCategory) -> [SDKTool] {
        return tools.filter { $0.category == category }
    }

    private func registerBuiltInTools() {
        register(SDKTool(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "JSON Formatter",
            category: .dataProcessor,
            inputSchema: [ToolParameter(key: "json", type: "string", required: true)],
            outputSchema: [ToolParameter(key: "formatted", type: "string", required: true)]
        ))

        register(SDKTool(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Text Summarizer",
            category: .aiUtility,
            inputSchema: [ToolParameter(key: "text", type: "string", required: true)],
            outputSchema: [ToolParameter(key: "summary", type: "string", required: true)]
        ))

        register(SDKTool(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "File Renamer",
            category: .fileTransformer,
            inputSchema: [ToolParameter(key: "pattern", type: "string", required: true)],
            outputSchema: [ToolParameter(key: "status", type: "string", required: true)]
        ))

        register(SDKTool(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Data Exporter",
            category: .workflowAction,
            inputSchema: [ToolParameter(key: "scope", type: "string", required: true)],
            outputSchema: [ToolParameter(key: "url", type: "string", required: true)]
        ))
    }
}
