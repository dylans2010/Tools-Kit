import Foundation
import FoundationModels

struct AgenticToolAITextSummarize: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "ai_text_summarize",
        description: "Summarize any text using Foundation Models",
        category: "ai_transform",
        inputSchema: ["text": "String", "maxLength": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let text = parameters["text"] ?? ""
        let maxLength = parameters["maxLength"] ?? "200"

        let session = LanguageModelSession(instructions: "You are a concise summarization engine. Produce clear, accurate summaries within the specified length.")
        let response = try await session.respond(to: "Summarize this text in approximately \(maxLength) words:\n\n\(text)")

        return AgenticToolOutput(
            summary: "Summarized \(text.count) chars to ~\(maxLength) words",
            generatedCode: nil,
            metadata: ["inputLength": "\(text.count)", "maxLength": maxLength],
            dataPayload: ["summary": response.content]
        )
    }
}
