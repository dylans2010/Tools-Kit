import Foundation

struct AgenticToolNoteSummarize: AgenticToolProtocol {
    let toolName = "AgenticToolNoteSummarize"
    let toolDescription = "Summarizes a note."
    let category = "NOTE"
    let inputSchema: [String: String] = ["noteId": "String"]
    let producesCode = false

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let noteId = parameters["noteId"] ?? "unknown"
        return AgenticToolOutput(
            summary: "The note \(noteId) was analyzed. It contains key insights about project velocity and team alignment.",
            generatedCode: nil,
            metadata: ["noteId": noteId]
        )
    }
}
