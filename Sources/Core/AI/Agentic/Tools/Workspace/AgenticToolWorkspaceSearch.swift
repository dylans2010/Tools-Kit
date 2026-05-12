import Foundation

struct AgenticToolWorkspaceSearch: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "workspace_search",
        description: "Search across entire workspace",
        category: "workspace",
        inputSchema: ["query": "String", "scope": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let query = parameters["query"] ?? ""
        let scope = parameters["scope"] ?? "all"
        let queryLower = query.lowercased()

        var results: [String: String] = [:]
        var totalMatches = 0

        // Search tasks
        let tasks = TasksManager.shared.tasks.filter { $0.title.lowercased().contains(queryLower) || $0.description.lowercased().contains(queryLower) }
        for task in tasks.prefix(5) {
            results["task_\(totalMatches)"] = "Task: \(task.title) [\(task.priority.rawValue)]"
            totalMatches += 1
        }

        // Search notes
        for notebook in NotebooksManager.shared.notebooks {
            for folder in notebook.folders {
                for page in folder.pages {
                    if page.title.lowercased().contains(queryLower) || page.content.lowercased().contains(queryLower) {
                        results["note_\(totalMatches)"] = "Note: \(page.title) [in: \(notebook.name)]"
                        totalMatches += 1
                    }
                }
            }
        }

        // Search calendar events
        let events = CalendarManager.shared.events.filter { $0.title.lowercased().contains(queryLower) }
        for event in events.prefix(5) {
            results["event_\(totalMatches)"] = "Event: \(event.title)"
            totalMatches += 1
        }

        // Search slide decks
        let decks = SlideDecksManager.shared.decks.filter { $0.title.lowercased().contains(queryLower) }
        for deck in decks.prefix(5) {
            results["deck_\(totalMatches)"] = "Deck: \(deck.title) (\(deck.slides.count) slides)"
            totalMatches += 1
        }

        // Search spreadsheets
        let sheets = SpreadsheetsManager.shared.spreadsheets.filter { $0.name.lowercased().contains(queryLower) }
        for sheet in sheets.prefix(5) {
            results["sheet_\(totalMatches)"] = "Sheet: \(sheet.name)"
            totalMatches += 1
        }

        results["totalMatches"] = "\(totalMatches)"

        return AgenticToolOutput(
            summary: "Found \(totalMatches) results for '\(query)' in scope '\(scope)'",
            generatedCode: nil,
            metadata: ["query": query, "scope": scope, "totalMatches": "\(totalMatches)"],
            dataPayload: results
        )
    }
}
