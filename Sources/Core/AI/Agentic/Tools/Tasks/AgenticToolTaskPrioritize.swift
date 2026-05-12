import Foundation
import FoundationModels

struct AgenticToolTaskPrioritize: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "task_prioritize",
        description: "Auto-prioritize tasks based on deadlines and importance",
        category: "tasks",
        inputSchema: ["strategy": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let strategy = parameters["strategy"] ?? "deadline"
        let manager = TasksManager.shared
        let tasks = manager.tasks.filter { !$0.completed }

        let taskDescriptions = tasks.prefix(20).map { "- \($0.title) [priority: \($0.priority.rawValue)]" }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a task prioritization engine. Analyze tasks and suggest optimal priority ordering.")
        let prompt = """
        Strategy: \(strategy)
        Current tasks:
        \(taskDescriptions)

        Provide a prioritized ranking with reasoning for each task.
        """

        let response = try await session.respond(to: prompt)
        let prioritization = response.content

        return AgenticToolOutput(
            summary: "Prioritized \(tasks.count) tasks using '\(strategy)' strategy",
            generatedCode: nil,
            metadata: ["strategy": strategy, "taskCount": "\(tasks.count)"],
            dataPayload: ["prioritization": prioritization]
        )
    }
}
