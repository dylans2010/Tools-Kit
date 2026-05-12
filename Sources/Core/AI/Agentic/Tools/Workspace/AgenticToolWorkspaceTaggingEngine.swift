import Foundation
import FoundationModels

struct AgenticToolWorkspaceTaggingEngine: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "workspace_tagging_engine",
        description: "Tag workspace items using AI classification",
        category: "workspace",
        inputSchema: ["itemId": "String", "autoDetect": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let itemId = parameters["itemId"] ?? ""
        let autoDetect = parameters["autoDetect"] ?? "true"

        var itemContent = ""
        var itemTitle = ""

        let targetId = UUID(uuidString: itemId)

        if let task = TasksManager.shared.tasks.first(where: { $0.id == targetId }) {
            itemTitle = task.title
            itemContent = "\(task.title): \(task.description)"
        } else {
            for notebook in NotebooksManager.shared.notebooks {
                for folder in notebook.folders {
                    if let page = folder.pages.first(where: { $0.id == targetId }) {
                        itemTitle = page.title
                        itemContent = "\(page.title): \(page.content.prefix(500))"
                        break
                    }
                }
            }
        }

        guard !itemContent.isEmpty else {
            throw AgenticToolExecutionError.executionFailed("workspace_tagging_engine", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Item not found"]))
        }

        let session = LanguageModelSession(instructions: "You are a content classification engine. Generate relevant tags as a comma-separated list.")
        let response = try await session.respond(to: "Generate tags for: \(itemContent)")

        let tags = response.content.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        return AgenticToolOutput(
            summary: "Tagged '\(itemTitle)' with \(tags.count) tags",
            generatedCode: nil,
            metadata: ["itemId": itemId, "autoDetect": autoDetect, "tagCount": "\(tags.count)"],
            dataPayload: ["tags": tags.joined(separator: ", ")]
        )
    }
}
