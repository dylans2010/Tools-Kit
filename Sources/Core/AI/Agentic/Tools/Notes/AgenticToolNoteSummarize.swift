import Foundation
import FoundationModels

struct AgenticToolNoteSummarize: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "note_summarize",
        description: "Summarize a note or set of notes using AI",
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
            throw AgenticToolExecutionError.executionFailed("note_summarize", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Note not found or empty"]))
        }

        let session = LanguageModelSession(instructions: "You are a summarization engine. Produce concise, accurate summaries.")
        let response = try await session.respond(to: "Summarize the following note titled '\(noteTitle)':\n\n\(noteContent)")

        return AgenticToolOutput(
            summary: "Summarized note '\(noteTitle)'",
            generatedCode: nil,
            metadata: ["noteId": noteIdStr, "originalLength": "\(noteContent.count)"],
            dataPayload: ["summary": response.content]
        )
    }
}
