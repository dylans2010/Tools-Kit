import Foundation

struct AgenticToolNoteCreate: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "note_create",
        description: "Create a new note in a notebook",
        category: "notes",
        inputSchema: ["notebookName": "String", "title": "String", "content": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let notebookName = parameters["notebookName"] ?? "Default"
        let title = parameters["title"] ?? "Untitled"
        let content = parameters["content"] ?? ""

        let manager = NotebooksManager.shared

        var notebook = manager.notebooks.first { $0.name.lowercased() == notebookName.lowercased() }
        if notebook == nil {
            notebook = manager.createNotebook(name: notebookName)
        }

        guard let nb = notebook else {
            throw AgenticToolExecutionError.executionFailed("note_create", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create or find notebook"]))
        }

        var folderID: UUID
        if let firstFolder = nb.folders.first {
            folderID = firstFolder.id
        } else {
            guard let newFolder = manager.addFolder(to: nb.id, name: "General") else {
                throw AgenticToolExecutionError.executionFailed("note_create", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create folder"]))
            }
            folderID = newFolder.id
        }

        manager.addPage(to: folderID, in: nb.id, title: title, content: content)

        return AgenticToolOutput(
            summary: "Created note '\(title)' in notebook '\(notebookName)'",
            generatedCode: nil,
            metadata: ["notebookId": nb.id.uuidString, "notebook": notebookName],
            dataPayload: ["title": title, "contentLength": "\(content.count)"]
        )
    }
}
