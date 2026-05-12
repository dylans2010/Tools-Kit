import Foundation
import FoundationModels

struct AgenticToolAIIdeaGenerator: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "ai_idea_generator",
        description: "Generate ideas based on a topic or context",
        category: "ai_transform",
        inputSchema: ["topic": "String", "count": "String"]
    )

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let topic = parameters["topic"] ?? ""
        let countStr = parameters["count"] ?? "5"
        let count = Int(countStr) ?? 5

        let session = LanguageModelSession(instructions: "You are a creative idea generator. Produce original, actionable, and diverse ideas.")
        let response = try await session.respond(to: "Generate \(count) creative ideas about: \(topic)\n\nFor each idea, provide a title, description, and potential impact.")

        return AgenticToolOutput(
            summary: "Generated \(count) ideas for '\(topic)'",
            generatedCode: nil,
            metadata: ["topic": topic, "count": countStr],
            dataPayload: ["ideas": response.content]
        )
    }
}
