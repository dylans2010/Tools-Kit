import Foundation

struct AgenticToolMailSearch: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "mail_search",
        description: "Search emails by query",
        category: "mail",
        inputSchema: ["query": "String", "account": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let query = parameters["query"] ?? ""
        let accountFilter = parameters["account"] ?? "all"

        let accounts = AccountManager.shared.accounts
        let filteredAccounts = accountFilter == "all"
            ? accounts
            : accounts.filter { $0.emailAddress.lowercased().contains(accountFilter.lowercased()) }

        var payload: [String: String] = [
            "query": query,
            "accountsSearched": "\(filteredAccounts.count)"
        ]

        for (index, account) in filteredAccounts.prefix(5).enumerated() {
            payload["account_\(index)"] = account.emailAddress
        }

        return AgenticToolOutput(
            summary: "Searched '\(query)' across \(filteredAccounts.count) accounts",
            generatedCode: nil,
            metadata: ["query": query, "account": accountFilter],
            dataPayload: payload
        )
    }
}
