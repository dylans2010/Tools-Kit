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

        let session = LanguageModelSession(instructions: "You are an email reply assistant. Generate contextual, well-written replies.")
        let prompt = """
        Generate an auto-reply for this email:
        \(emailContent.isEmpty ? "Email ID: \(emailId)" : emailContent)
        Tone: \(tone)
        Write a contextual, helpful reply that addresses the email's content.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Generated \(tone) auto-reply for email '\(emailSubject.isEmpty ? emailId : emailSubject)'",
            generatedCode: nil,
            metadata: ["emailId": emailId, "tone": tone],
            dataPayload: ["reply": response.content]
        )
    }
}
