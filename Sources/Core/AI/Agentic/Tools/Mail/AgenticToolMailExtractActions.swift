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

        var emailContent = ""
        var emailSubject = ""
        let threads = MailStore.shared.threads
        if let threadUUID = UUID(uuidString: emailId) {
            for thread in threads {
                for message in thread.messages where message.id == threadUUID {
                    emailSubject = message.subject
                    emailContent = "Subject: \(message.subject)\nFrom: \(message.from)\nBody: \(message.body)"
                    break
                }
                if !emailContent.isEmpty { break }
            }
        }

        let session = LanguageModelSession(instructions: "You are an action item extraction engine. Extract all actionable items from email content.")
        let prompt = """
        Extract action items from this email:
        \(emailContent.isEmpty ? "Email ID: \(emailId)" : emailContent)
        Identify: tasks, deadlines, follow-ups, decisions needed, and commitments made.
        Format each action item with priority and suggested deadline.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Extracted action items from email '\(emailSubject.isEmpty ? emailId : emailSubject)'",
            generatedCode: nil,
            metadata: ["emailId": emailId],
            dataPayload: ["actions": response.content]
        )
    }
}
