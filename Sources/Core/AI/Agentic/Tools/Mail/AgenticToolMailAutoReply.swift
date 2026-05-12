import Foundation
import FoundationModels

struct AgenticToolMailAutoReply: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "mail_auto_reply",
        description: "Generate an AI auto-reply for an email",
        category: "mail",
        inputSchema: ["emailId": "String", "tone": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let emailId = parameters["emailId"] ?? ""
        let tone = parameters["tone"] ?? "professional"

        let session = LanguageModelSession(instructions: "You are an email reply assistant. Generate contextual, well-written replies.")
        let prompt = """
        Generate an auto-reply for email ID: \(emailId)
        Tone: \(tone)
        Write a contextual, helpful reply that addresses the email's content.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Generated \(tone) auto-reply for email '\(emailId)'",
            generatedCode: nil,
            metadata: ["emailId": emailId, "tone": tone],
            dataPayload: ["reply": response.content]
        )
    }
}
