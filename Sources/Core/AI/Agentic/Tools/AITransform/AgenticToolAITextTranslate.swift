import Foundation
import FoundationModels

struct AgenticToolAITextTranslate: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "ai_text_translate",
        description: "Translate text to another language",
        category: "ai_transform",
        inputSchema: ["text": "String", "targetLanguage": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let text = parameters["text"] ?? ""
        let targetLanguage = parameters["targetLanguage"] ?? "Spanish"

        let session = LanguageModelSession(instructions: "You are a translation engine. Translate text accurately while maintaining natural phrasing in the target language.")
        let response = try await session.respond(to: "Translate the following text to \(targetLanguage):\n\n\(text)")

        return AgenticToolOutput(
            summary: "Translated text to \(targetLanguage)",
            generatedCode: nil,
            metadata: ["targetLanguage": targetLanguage, "inputLength": "\(text.count)"],
            dataPayload: ["translation": response.content]
        )
    }
}
