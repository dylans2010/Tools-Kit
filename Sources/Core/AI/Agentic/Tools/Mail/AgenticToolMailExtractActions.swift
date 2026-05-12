import Foundation
import FoundationModels

struct AgenticToolMailExtractActions: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "mail_extract_actions",
        description: "Extract action items from emails",
        category: "mail",
        inputSchema: ["emailId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let emailId = parameters["emailId"] ?? ""

        let session = LanguageModelSession(instructions: "You are an action item extraction engine. Extract all actionable items from email content.")
        let prompt = """
        Extract action items from email ID: \(emailId)
        Identify: tasks, deadlines, follow-ups, decisions needed, and commitments made.
        Format each action item with priority and suggested deadline.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Extracted action items from email '\(emailId)'",
            generatedCode: nil,
            metadata: ["emailId": emailId],
            dataPayload: ["actions": response.content]
        )
    }
}
