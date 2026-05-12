import Foundation

struct AgenticToolNoteUpdate: AgenticToolProtocol {
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

        for (nbIndex, notebook) in manager.notebooks.enumerated() {
            for (fIndex, folder) in notebook.folders.enumerated() {
                for (pIndex, page) in folder.pages.enumerated() {
                    if page.id == noteId {
                        var updatedNotebook = notebook
                        var updatedFolder = folder
                        var updatedPage = page
                        updatedPage.content = newContent
                        updatedFolder.pages[pIndex] = updatedPage
                        updatedNotebook.folders[fIndex] = updatedFolder
                        manager.updateNotebook(updatedNotebook)
                        noteTitle = page.title
                        found = true
                        break
                    }
                }
                if found { break }
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
