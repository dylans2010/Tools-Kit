import Foundation

struct AgenticToolTaskCreate: AgenticToolProtocol {
    let toolName = "AgenticToolTaskCreate"
    let toolDescription = "Creates a new task in the workspace."
    let category = "TASK SYSTEM"
    let inputSchema = [
        "title": "The title of the task",
        "priority": "The priority (High, Medium, Low)",
        "dueDate": "ISO8601 date string"
    ]
    let producesCode = false

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        guard let title = parameters["title"] else {
            throw NSError(domain: "AgenticToolTaskCreate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing title"])
        }

        // In a real implementation, this would interact with WorkspaceTaskStore
        print("[Agentic] Creating task: \(title)")

        return AgenticToolOutput(
            summary: "Successfully created task: \(title)",
            generatedCode: nil,
            metadata: ["status": "success", "taskTitle": title]
        )
    }
}
