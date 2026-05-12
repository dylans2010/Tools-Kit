import Foundation

struct AgenticToolWorkspaceOpenItem: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "workspace_open_item",
        description: "Open a workspace item by ID or name",
        category: "workspace",
        inputSchema: ["itemId": "String", "itemType": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let itemId = parameters["itemId"] ?? ""
        let itemType = parameters["itemType"] ?? "auto"

        var foundItem: String?
        var itemDetail: [String: String] = [:]

        let targetId = UUID(uuidString: itemId)

        switch itemType.lowercased() {
        case "task":
            if let task = TasksManager.shared.tasks.first(where: { $0.id == targetId || $0.title.lowercased() == itemId.lowercased() }) {
                foundItem = task.title
                itemDetail = ["type": "task", "title": task.title, "priority": task.priority.rawValue, "completed": "\(task.completed)"]
            }
        case "note":
            for notebook in NotebooksManager.shared.notebooks {
                for folder in notebook.folders {
                    if let page = folder.pages.first(where: { $0.id == targetId || $0.title.lowercased() == itemId.lowercased() }) {
                        foundItem = page.title
                        itemDetail = ["type": "note", "title": page.title, "notebook": notebook.name, "content": String(page.content.prefix(500))]
                        break
                    }
                }
            }
        case "event":
            if let event = CalendarManager.shared.events.first(where: { $0.id == targetId || $0.title.lowercased() == itemId.lowercased() }) {
                foundItem = event.title
                itemDetail = ["type": "event", "title": event.title, "description": event.description]
            }
        default:
            if let task = TasksManager.shared.tasks.first(where: { $0.id == targetId || $0.title.lowercased() == itemId.lowercased() }) {
                foundItem = task.title
                itemDetail = ["type": "task", "title": task.title]
            }
        }

        guard let name = foundItem else {
            throw AgenticToolExecutionError.executionFailed("workspace_open_item", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Item not found"]))
        }

        return AgenticToolOutput(
            summary: "Opened workspace item '\(name)'",
            generatedCode: nil,
            metadata: ["itemId": itemId, "itemType": itemType],
            dataPayload: itemDetail
        )
    }
}
