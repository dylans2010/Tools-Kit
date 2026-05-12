import Foundation

final class AgenticToolExecutor {
    static let shared = AgenticToolExecutor()

    private let tools: [String: any AgenticToolProtocol]

    private init() {
        // Register available tools
        let availableTools: [any AgenticToolProtocol] = [
            AgenticToolTaskCreate(),
            AgenticToolNoteSummarize(),
            AgenticToolCodeSwiftUIViewGenerator(),
            AgenticToolAITextSummarize()
        ]
        self.tools = Dictionary(uniqueKeysWithValues: availableTools.map { ($0.toolName, $0) })
    }

    func execute(toolName: String, parameters: [String: String]) async throws -> AgenticToolOutput {
        guard let tool = tools[toolName] else {
            throw NSError(domain: "AgenticToolExecutor", code: 404, userInfo: [NSLocalizedDescriptionKey: "Tool not found: \(toolName)"])
        }

        // Validate schema (simplified for this implementation)
        for key in tool.inputSchema.keys {
            if parameters[key] == nil {
                print("[AgenticToolExecutor] Warning: Missing parameter \(key) for tool \(toolName)")
            }
        }

        return try await tool.execute(parameters: parameters)
    }
}
