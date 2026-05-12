import Foundation
import FoundationModels

struct AgenticToolNoteExtractInsights: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "note_extract_insights",
        description: "Extract key insights and action items from notes",
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
            throw AgenticToolExecutionError.executionFailed("note_extract_insights", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Note not found or empty"]))
        }

        let session = LanguageModelSession(instructions: "You are an insight extraction engine. Extract key insights, action items, decisions, and important points.")
        let response = try await session.respond(to: "Extract insights from this note titled '\(noteTitle)':\n\n\(noteContent)")

        return AgenticToolOutput(
            summary: "Extracted insights from '\(noteTitle)'",
            generatedCode: nil,
            metadata: ["noteId": noteIdStr],
            dataPayload: ["insights": response.content]
        )
    }
}
