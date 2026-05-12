import Foundation

struct AgenticToolTaskCreate: AgenticToolProtocol {
    let toolName = "AgenticToolTaskCreate"
    let toolDescription = "Creates a new task."
    let category = "TASK"
    let inputSchema: [String: String] = ["title": "String"]
    let producesCode = false

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let title = parameters["title"] ?? "Untitled Task"
        return AgenticToolOutput(
            summary: "Task '\(title)' has been created in your workspace.",
            generatedCode: nil,
            metadata: ["title": title]
        )
    }
}
