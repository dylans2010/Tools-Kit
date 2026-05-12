import Foundation

struct AgenticToolWorkspaceIndexBuilder: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "workspace_index_builder",
        description: "Build or rebuild the workspace search index",
        category: "workspace",
        inputSchema: ["scope": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let scope = parameters["scope"] ?? "all"

        var indexedItems = 0

        let tasks = TasksManager.shared.tasks
        indexedItems += tasks.count

        for notebook in NotebooksManager.shared.notebooks {
            for folder in notebook.folders {
                indexedItems += folder.pages.count
            }
        }

        let events = CalendarManager.shared.events
        indexedItems += events.count

        let decks = SlideDecksManager.shared.decks
        indexedItems += decks.count

        let sheets = SpreadsheetsManager.shared.spreadsheets
        indexedItems += sheets.count

        let spaces = CollaborationManager.shared.spaces
        indexedItems += spaces.count

        return AgenticToolOutput(
            summary: "Built workspace index: \(indexedItems) items indexed (scope: \(scope))",
            generatedCode: nil,
            metadata: [
                "scope": scope,
                "totalIndexed": "\(indexedItems)",
                "tasks": "\(tasks.count)",
                "events": "\(events.count)",
                "decks": "\(decks.count)",
                "sheets": "\(sheets.count)"
            ],
            dataPayload: ["indexStatus": "complete", "itemCount": "\(indexedItems)"]
        )
    }
}
