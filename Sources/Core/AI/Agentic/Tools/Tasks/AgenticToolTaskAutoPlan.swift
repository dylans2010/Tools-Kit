import Foundation
import FoundationModels

struct AgenticToolTaskAutoPlan: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "task_auto_plan",
        description: "Generate an execution plan for a set of tasks",
        category: "tasks",
        inputSchema: ["scope": "String", "timeframe": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let scope = parameters["scope"] ?? "all"
        let timeframe = parameters["timeframe"] ?? "week"

        let manager = TasksManager.shared
        let tasks = manager.tasks.filter { !$0.completed }

        let taskList = tasks.prefix(30).map { "- \($0.title) [\($0.priority.rawValue)]" }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a project planning AI. Create actionable execution plans.")
        let prompt = """
        Scope: \(scope)
        Timeframe: \(timeframe)
        Tasks:
        \(taskList)

        Generate a detailed execution plan with daily breakdowns, dependencies, and milestones.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Generated auto-plan for \(tasks.count) tasks over \(timeframe)",
            generatedCode: nil,
            metadata: ["scope": scope, "timeframe": timeframe, "taskCount": "\(tasks.count)"],
            dataPayload: ["plan": response.content]
        )
    }
}
