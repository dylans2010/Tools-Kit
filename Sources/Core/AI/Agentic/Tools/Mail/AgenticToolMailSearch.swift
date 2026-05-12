import Foundation

struct AgenticToolMailSearch: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "mail_search",
        description: "Search emails by query across threads and messages",
        category: "mail",
        inputSchema: ["query": "String", "account": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let query = parameters["query"] ?? ""
        let accountFilter = parameters["account"] ?? "all"
        let queryLower = query.lowercased()

        let threads = MailStore.shared.threads
        var matchingResults: [String] = []

        for thread in threads {
            for message in thread.messages {
                if message.subject.lowercased().contains(queryLower) ||
                   message.body.lowercased().contains(queryLower) ||
                   message.from.lowercased().contains(queryLower) {
                    matchingResults.append("\(message.subject) | From: \(message.from) | \(message.date)")
                }
            }
        }

        var payload: [String: String] = [
            "query": query,
            "resultCount": "\(matchingResults.count)"
        ]

        for (index, result) in matchingResults.prefix(20).enumerated() {
            payload["result_\(index)"] = result
        }

        return AgenticToolOutput(
            summary: "Found \(matchingResults.count) emails matching '\(query)'",
            generatedCode: nil,
            metadata: ["query": query, "account": accountFilter, "resultCount": "\(matchingResults.count)"],
            dataPayload: payload
        )
    }
}
