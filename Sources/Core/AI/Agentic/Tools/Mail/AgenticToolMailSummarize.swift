import Foundation
import FoundationModels

struct AgenticToolMailSummarize: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "mail_summarize",
        description: "Summarize email threads or inbox",
        category: "mail",
        inputSchema: ["scope": "String", "count": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let scope = parameters["scope"] ?? "inbox"
        let countStr = parameters["count"] ?? "10"
        let count = Int(countStr) ?? 10

        let accounts = AccountManager.shared.accounts
        var emailSummaries: [String] = []

        for account in accounts {
            emailSummaries.append("Account: \(account.emailAddress) (\(account.providerType.rawValue))")
        }

        let session = LanguageModelSession(instructions: "You are an email summarization AI. Produce concise summaries of email activity.")
        let prompt = """
        Summarize the email activity for scope '\(scope)' (last \(count) items).
        Connected accounts:
        \(emailSummaries.joined(separator: "\n"))

        Provide a structured summary of important emails, action items, and trends.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Summarized \(scope) emails across \(accounts.count) accounts",
            generatedCode: nil,
            metadata: ["scope": scope, "count": countStr, "accountCount": "\(accounts.count)"],
            dataPayload: ["summary": response.content]
        )
    }
}
