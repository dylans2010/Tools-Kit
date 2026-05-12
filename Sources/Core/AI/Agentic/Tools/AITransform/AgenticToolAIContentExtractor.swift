import Foundation
import FoundationModels

struct AgenticToolAIContentExtractor: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "ai_content_extractor",
        description: "Extract structured data from unstructured text",
        category: "ai_transform",
        inputSchema: ["text": "String", "extractionType": "String"]
    )

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let text = parameters["text"] ?? ""
        let extractionType = parameters["extractionType"] ?? "entities"

        let session = LanguageModelSession(instructions: "You are a data extraction engine. Extract structured information from unstructured text.")
        let response = try await session.respond(to: "Extract \(extractionType) from this text:\n\n\(text)\n\nProvide structured output with labels and values.")

        return AgenticToolOutput(
            summary: "Extracted \(extractionType) from text (\(text.count) chars)",
            generatedCode: nil,
            metadata: ["extractionType": extractionType, "inputLength": "\(text.count)"],
            dataPayload: ["extracted": response.content]
        )
    }
}
