import Foundation

struct AgenticToolNoteCreate: AgenticToolProtocol {
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
        let notebook = manager.notebooks.first { $0.name == notebookName }

        let page = NotebookPage(title: title, content: content)

        if var nb = notebook, let firstFolder = nb.folders.first {
            var folder = firstFolder
            folder.pages.append(page)
            nb.folders[0] = folder
            manager.updateNotebook(nb)
        }

        return AgenticToolOutput(
            summary: "Created note '\(title)' in notebook '\(notebookName)'",
            generatedCode: nil,
            metadata: ["pageId": page.id.uuidString, "notebook": notebookName],
            dataPayload: ["title": title, "contentLength": "\(content.count)"]
        )
    }
}
