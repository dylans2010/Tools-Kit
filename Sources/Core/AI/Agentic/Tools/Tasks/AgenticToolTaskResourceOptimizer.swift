import Foundation
import FoundationModels

struct AgenticToolTaskResourceOptimizer: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "task_resource_optimizer",
        description: "Optimize resource allocation across tasks",
        category: "tasks",
        inputSchema: ["constraints": "String", "resources": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let constraints = parameters["constraints"] ?? "time"
        let resources = parameters["resources"] ?? "default"

        let manager = TasksManager.shared
        let tasks = manager.tasks.filter { !$0.completed }

        let taskList = tasks.prefix(30).map { "- \($0.title) [priority: \($0.priority.rawValue)]" }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a resource optimization AI. Allocate resources optimally across tasks.")
        let prompt = """
        Constraints: \(constraints)
        Available resources: \(resources)
        Tasks:
        \(taskList)

        Provide an optimal resource allocation plan that minimizes time and maximizes throughput.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Resource optimization complete for \(tasks.count) tasks",
            generatedCode: nil,
            metadata: ["constraints": constraints, "resources": resources, "taskCount": "\(tasks.count)"],
            dataPayload: ["optimization": response.content]
        )
    }
}
