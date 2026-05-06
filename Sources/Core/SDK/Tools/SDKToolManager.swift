import Foundation
import Combine

public struct SDKTool: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var category: SDKToolCategory
    public var inputSchema: [ToolParameter]
    public var outputSchema: [ToolParameter]
    public var pluginID: UUID?
}

public struct ToolParameter: Codable {
    public var key: String
    public var type: String
    public var required: Bool
}

public enum SDKToolCategory: String, Codable, CaseIterable {
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

        switch tool.name {
        case "JSON Formatter":
            if let jsonString = input["json"] as? String,
               let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                output["formatted"] = String(data: prettyData, encoding: .utf8) ?? ""
            } else {
                throw SDKError.executionFailed(reason: "Invalid JSON input")
            }
        case "Text Summarizer":
            if let text = input["text"] as? String {
                let response = try await WorkspaceAPI.shared.persona.queryPersona(prompt: "Summarize in 2-3 sentences: \(text.prefix(2000))")
                output["summary"] = response
            } else {
                throw SDKError.executionFailed(reason: "Missing text input")
            }
        case "File Renamer":
            let pattern = input["pattern"] as? String ?? "*"
            let files = WorkspaceAPI.shared.files.listFiles()
            let matched = files.filter { $0.name.contains(pattern) || pattern == "*" }
            output["matchedCount"] = "\(matched.count)"
            output["files"] = matched.map { $0.name }.joined(separator: ", ")
        case "Data Exporter":
            let scopeStr = input["scope"] as? String ?? "all"
            let scope: SDKScope = SDKScope.allCases.first { String(describing: $0) == scopeStr } ?? .all
            let items = try await SDKDataEngine.shared.fetch(scope: scope)
            let exportData = items.map { ["id": $0.id.uuidString, "title": $0.title, "scope": String(describing: $0.scope)] }
            if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                let exportURL = appSupport.appendingPathComponent("sdk_export_\(Int(Date().timeIntervalSince1970)).json")
                try jsonData.write(to: exportURL)
                output["url"] = exportURL.absoluteString
                output["itemCount"] = "\(items.count)"
            }
        default:
            SDKLogStore.shared.log("No handler for tool: \(tool.name)", source: "SDKToolManager", level: .warning)
        }

        let duration = Date().timeIntervalSince(start)
        return SDKToolResult(toolID: toolID, output: output, duration: duration, success: true)
    }

    public func tools(for category: SDKToolCategory) -> [SDKTool] {
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
            outputSchema: [ToolParameter(key: "matchedCount", type: "string", required: true), ToolParameter(key: "files", type: "string", required: false)]
        ))

        register(SDKTool(
            id: UUID(),
            name: "Data Exporter",
            category: .workflowAction,
            inputSchema: [ToolParameter(key: "scope", type: "string", required: true)],
            outputSchema: [ToolParameter(key: "url", type: "string", required: true), ToolParameter(key: "itemCount", type: "string", required: false)]
        ))
    }
}
