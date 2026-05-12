import Foundation
import FoundationModels

struct AgenticToolMailPriorityClassifier: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "mail_priority_classifier",
        description: "Classify email priority using AI",
        category: "mail",
        inputSchema: ["scope": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let scope = parameters["scope"] ?? "inbox"

        let accounts = AccountManager.shared.accounts
        let threads = MailStore.shared.threads

        var emailDescriptions: [String] = []
        for thread in threads.prefix(20) {
            if let lastMessage = thread.messages.last {
                emailDescriptions.append("- Subject: \(lastMessage.subject) | From: \(lastMessage.from) | Date: \(lastMessage.date)")
            }
        }

        let session = LanguageModelSession(instructions: "You are an email priority classifier. Categorize emails into urgency levels: critical, high, medium, low.")
        let prompt = """
        Classify email priorities for scope: \(scope)
        Accounts: \(accounts.map { $0.emailAddress }.joined(separator: ", "))

        Recent emails:
        \(emailDescriptions.joined(separator: "\n"))

        Analyze and classify each email by urgency. Provide classification criteria and rationale.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Classified \(emailDescriptions.count) email priorities for '\(scope)' scope",
            generatedCode: nil,
            metadata: ["scope": scope, "accountCount": "\(accounts.count)", "emailCount": "\(emailDescriptions.count)"],
            dataPayload: ["classification": response.content]
        )
    }
}
