import Foundation

struct AgenticToolNoteDelete: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "note_delete",
        description: "Delete a note by ID",
        category: "notes",
        inputSchema: ["noteId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let noteIdStr = parameters["noteId"] ?? ""

        guard let noteId = UUID(uuidString: noteIdStr) else {
            throw AgenticToolExecutionError.executionFailed("note_delete", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid note ID"]))
        }

        let manager = NotebooksManager.shared
        var deletedTitle = ""

        for notebook in manager.notebooks {
            for folder in notebook.folders {
                if let page = folder.pages.first(where: { $0.id == noteId }) {
                    deletedTitle = page.title
                    var updatedNotebook = notebook
                    var updatedFolder = folder
                    updatedFolder.pages.removeAll { $0.id == noteId }
                    if let fIdx = updatedNotebook.folders.firstIndex(where: { $0.id == folder.id }) {
                        updatedNotebook.folders[fIdx] = updatedFolder
                    }
                    manager.updateNotebook(updatedNotebook)
                    break
                }
            }
        }

        return AgenticToolOutput(
            summary: "Deleted note '\(deletedTitle)' (\(noteIdStr))",
            generatedCode: nil,
            metadata: ["noteId": noteIdStr, "deleted": "true"],
            dataPayload: ["deletedTitle": deletedTitle]
        )
    }
}
