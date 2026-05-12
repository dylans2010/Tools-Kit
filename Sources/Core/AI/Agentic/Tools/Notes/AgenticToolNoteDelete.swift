import Foundation

struct AgenticToolNoteDelete: AgenticToolProtocol, Sendable {
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
        var found = false

        for notebook in manager.notebooks {
            for folder in notebook.folders {
                if let page = folder.pages.first(where: { $0.id == noteId }) {
                    deletedTitle = page.title
                    var updatedFolder = folder
                    updatedFolder.pages.removeAll { $0.id == noteId }
                    manager.updateFolder(updatedFolder, in: notebook)
                    found = true
                    break
                }
            }
            if found { break }
        }

        guard found else {
            throw AgenticToolExecutionError.executionFailed("note_delete", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Note not found"]))
        }

        return AgenticToolOutput(
            summary: "Deleted note '\(deletedTitle)' (\(noteIdStr))",
            generatedCode: nil,
            metadata: ["noteId": noteIdStr, "deleted": "true"],
            dataPayload: ["deletedTitle": deletedTitle]
        )
    }
}
