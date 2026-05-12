import Foundation
import FoundationModels

struct AgenticToolAITextRewrite: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "ai_text_rewrite",
        description: "Rewrite text in a different tone or style",
        category: "ai_transform",
        inputSchema: ["text": "String", "style": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let text = parameters["text"] ?? ""
        let style = parameters["style"] ?? "professional"

        let session = LanguageModelSession(instructions: "You are a text rewriting engine. Rewrite text while preserving meaning but changing style and tone.")
        let response = try await session.respond(to: "Rewrite the following text in a '\(style)' style:\n\n\(text)")

        return AgenticToolOutput(
            summary: "Rewrote text in '\(style)' style",
            generatedCode: nil,
            metadata: ["style": style, "inputLength": "\(text.count)"],
            dataPayload: ["rewritten": response.content]
        )
    }
}
