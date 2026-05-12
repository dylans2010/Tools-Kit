import Foundation
import FoundationModels

struct AgenticToolAIClassifier: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "ai_classifier",
        description: "Classify text into categories",
        category: "ai_transform",
        inputSchema: ["text": "String", "categories": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let text = parameters["text"] ?? ""
        let categoriesStr = parameters["categories"] ?? "general,work,personal,urgent"

        let session = LanguageModelSession(instructions: "You are a text classification engine. Classify text into the provided categories with confidence scores.")
        let response = try await session.respond(to: "Classify this text into these categories: [\(categoriesStr)]\n\nText: \(text)\n\nProvide classification with confidence scores.")

        return AgenticToolOutput(
            summary: "Classified text into [\(categoriesStr)]",
            generatedCode: nil,
            metadata: ["categories": categoriesStr, "inputLength": "\(text.count)"],
            dataPayload: ["classification": response.content]
        )
    }
}
