import Foundation

struct AgenticToolNoteUpdate: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "note_update",
        description: "Update an existing note",
        category: "notes",
        inputSchema: ["noteId": "String", "content": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let noteIdStr = parameters["noteId"] ?? ""
        let newContent = parameters["content"] ?? ""

        guard let noteId = UUID(uuidString: noteIdStr) else {
            throw AgenticToolExecutionError.executionFailed("note_update", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid note ID"]))
        }

        let manager = NotebooksManager.shared
        var found = false
        var noteTitle = ""

        for notebook in manager.notebooks {
            for folder in notebook.folders {
                if var page = folder.pages.first(where: { $0.id == noteId }) {
                    noteTitle = page.title
                    page.content = newContent
                    manager.updatePage(page, in: folder.id, notebookID: notebook.id)
                    found = true
                    break
                }
            }
            if found { break }
        }

        guard found else {
            throw AgenticToolExecutionError.executionFailed("note_update", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Note not found"]))
        }

        return AgenticToolOutput(
            summary: "Updated note '\(noteTitle)' with new content (\(newContent.count) chars)",
            generatedCode: nil,
            metadata: ["noteId": noteIdStr],
            dataPayload: ["contentLength": "\(newContent.count)"]
        )
    }
}
