import Foundation
import FoundationModels

struct AgenticToolNoteAutoTag: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "note_auto_tag",
        description: "Automatically tag notes based on content analysis",
        category: "notes",
        inputSchema: ["noteId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let noteIdStr = parameters["noteId"] ?? ""

        let manager = NotebooksManager.shared
        var noteContent = ""
        var noteTitle = ""

        if let noteId = UUID(uuidString: noteIdStr) {
            for notebook in manager.notebooks {
                for folder in notebook.folders {
                    if let page = folder.pages.first(where: { $0.id == noteId }) {
                        noteContent = page.content
                        noteTitle = page.title
                        break
                    }
                }
            }
        }

        guard !noteContent.isEmpty else {
            throw AgenticToolExecutionError.executionFailed("note_auto_tag", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Note not found or empty"]))
        }

        let session = LanguageModelSession(instructions: "You are a content tagging engine. Analyze text and produce relevant tags as a comma-separated list.")
        let response = try await session.respond(to: "Generate tags for this note titled '\(noteTitle)':\n\n\(noteContent)")

        let tags = response.content.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        if let noteId = UUID(uuidString: noteIdStr) {
            for notebook in manager.notebooks {
                for folder in notebook.folders {
                    if var page = folder.pages.first(where: { $0.id == noteId }) {
                        page.tags = Array(Set(page.tags + tags))
                        manager.updatePage(page, in: folder.id, notebookID: notebook.id)
                        break
                    }
                }
            }
        }

        var payload: [String: String] = ["tagCount": "\(tags.count)"]
        for (index, tag) in tags.prefix(20).enumerated() {
            payload["tag_\(index)"] = tag
        }

        return AgenticToolOutput(
            summary: "Auto-tagged '\(noteTitle)' with \(tags.count) tags",
            generatedCode: nil,
            metadata: ["noteId": noteIdStr, "tagCount": "\(tags.count)"],
            dataPayload: payload
        )
    }
}
