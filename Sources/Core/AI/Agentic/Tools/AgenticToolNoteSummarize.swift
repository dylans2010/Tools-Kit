import Foundation

struct AgenticToolNoteSummarize: AgenticToolProtocol {
    let toolName = "AgenticToolNoteSummarize"
    let toolDescription = "Summarizes a note and extracts key points."
    let category = "NOTES SYSTEM"
    let inputSchema = [
        "noteId": "The unique identifier of the note",
        "detailLevel": "The level of detail (Concise, Detailed)"
    ]
    let producesCode = false

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        guard let noteId = parameters["noteId"] else {
            throw NSError(domain: "AgenticToolNoteSummarize", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing noteId"])
        }

        print("[Agentic] Summarizing note: \(noteId)")

        let summary = "This is a summarized version of the note \(noteId). It highlights the key project milestones and upcoming deadlines."

        return AgenticToolOutput(
            summary: summary,
            generatedCode: nil,
            metadata: ["noteId": noteId, "status": "completed"]
        )
    }
}
