import Foundation
import FoundationModels

struct AgenticToolMailDraft: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "mail_draft",
        description: "Draft an email using AI",
        category: "mail",
        inputSchema: ["to": "String", "subject": "String", "context": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let to = parameters["to"] ?? ""
        let subject = parameters["subject"] ?? ""
        let context = parameters["context"] ?? ""

        let session = LanguageModelSession(instructions: "You are a professional email drafting assistant. Write clear, professional emails.")
        let prompt = """
        Draft an email:
        To: \(to)
        Subject: \(subject)
        Context: \(context)

        Write a professional, well-structured email body.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Drafted email to '\(to)' about '\(subject)'",
            generatedCode: nil,
            metadata: ["to": to, "subject": subject],
            dataPayload: ["draft": response.content]
        )
    }
}
