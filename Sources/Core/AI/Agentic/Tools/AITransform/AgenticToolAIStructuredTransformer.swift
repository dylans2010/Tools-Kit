import Foundation
import FoundationModels

struct AgenticToolAIStructuredTransformer: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "ai_structured_transformer",
        description: "Transform text into a structured format",
        category: "ai_transform",
        inputSchema: ["text": "String", "outputFormat": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let text = parameters["text"] ?? ""
        let outputFormat = parameters["outputFormat"] ?? "json"

        let session = LanguageModelSession(instructions: "You are a data transformation engine. Convert unstructured text into the specified structured format.")
        let response = try await session.respond(to: "Transform this text into \(outputFormat) format:\n\n\(text)")

        return AgenticToolOutput(
            summary: "Transformed text to \(outputFormat) format",
            generatedCode: nil,
            metadata: ["outputFormat": outputFormat, "inputLength": "\(text.count)"],
            dataPayload: ["transformed": response.content]
        )
    }
}
