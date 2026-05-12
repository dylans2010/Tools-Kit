import Foundation

struct AgenticToolNoteSearch: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "note_search",
        description: "Search notes by query string",
        category: "notes",
        inputSchema: ["query": "String", "scope": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let query = parameters["query"] ?? ""
        let scope = parameters["scope"] ?? "all"

        let manager = NotebooksManager.shared
        var results: [(String, String, String)] = []

        for notebook in manager.notebooks {
            if scope != "all" && notebook.name.lowercased() != scope.lowercased() { continue }
            for folder in notebook.folders {
                for page in folder.pages {
                    let searchable = "\(page.title) \(page.content)".lowercased()
                    if searchable.contains(query.lowercased()) {
                        results.append((page.id.uuidString, page.title, notebook.name))
                    }
                }
            }
        }

        var payload: [String: String] = ["resultCount": "\(results.count)"]
        for (index, result) in results.prefix(20).enumerated() {
            payload["result_\(index)"] = "\(result.1) [in: \(result.2)] (id: \(result.0))"
        }

        return AgenticToolOutput(
            summary: "Found \(results.count) notes matching '\(query)' in scope '\(scope)'",
            generatedCode: nil,
            metadata: ["query": query, "scope": scope, "resultCount": "\(results.count)"],
            dataPayload: payload
        )
    }
}
