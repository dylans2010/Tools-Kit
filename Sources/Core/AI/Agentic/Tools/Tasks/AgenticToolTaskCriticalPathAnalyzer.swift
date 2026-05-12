import Foundation
import FoundationModels

struct AgenticToolTaskCriticalPathAnalyzer: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "task_critical_path",
        description: "Analyze the critical path through task dependencies",
        category: "tasks",
        inputSchema: ["projectScope": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let projectScope = parameters["projectScope"] ?? "all"
        let manager = TasksManager.shared
        let tasks = manager.tasks.filter { !$0.completed }

        let taskList = tasks.prefix(30).map { "- \($0.title) [priority: \($0.priority.rawValue)]" }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a project management AI specializing in critical path analysis.")
        let prompt = """
        Project scope: \(projectScope)
        Tasks:
        \(taskList)

        Identify the critical path, bottlenecks, and suggest optimizations to reduce the overall project timeline.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Critical path analysis complete for \(tasks.count) tasks in scope '\(projectScope)'",
            generatedCode: nil,
            metadata: ["projectScope": projectScope, "taskCount": "\(tasks.count)"],
            dataPayload: ["analysis": response.content]
        )
    }
}
