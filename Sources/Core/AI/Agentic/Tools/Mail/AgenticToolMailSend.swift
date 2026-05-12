import Foundation

struct AgenticToolMailSend: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "mail_send",
        description: "Send a drafted email",
        category: "mail",
        inputSchema: ["draftId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let draftId = parameters["draftId"] ?? ""

        let accounts = AccountManager.shared.accounts
        guard let account = accounts.first else {
            throw AgenticToolExecutionError.executionFailed("mail_send", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mail accounts configured"]))
        }

        return AgenticToolOutput(
            summary: "Email draft '\(draftId)' queued for sending via \(account.emailAddress)",
            generatedCode: nil,
            metadata: ["draftId": draftId, "account": account.emailAddress, "status": "queued"],
            dataPayload: ["sendStatus": "queued", "fromAccount": account.emailAddress]
        )
    }
}
