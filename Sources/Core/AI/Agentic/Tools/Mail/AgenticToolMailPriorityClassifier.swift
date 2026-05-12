import Foundation
import FoundationModels

struct AgenticToolMailPriorityClassifier: AgenticToolProtocol {
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
        let accountInfo = accounts.map { "\($0.emailAddress) (\($0.providerType.rawValue))" }.joined(separator: ", ")

        let session = LanguageModelSession(instructions: "You are an email priority classifier. Categorize emails into urgency levels: critical, high, medium, low.")
        let prompt = """
        Classify email priorities for scope: \(scope)
        Accounts: \(accountInfo)

        Analyze and classify emails by urgency. Provide classification criteria and rationale.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Classified email priorities for '\(scope)' scope",
            generatedCode: nil,
            metadata: ["scope": scope, "accountCount": "\(accounts.count)"],
            dataPayload: ["classification": response.content]
        )
    }
}
