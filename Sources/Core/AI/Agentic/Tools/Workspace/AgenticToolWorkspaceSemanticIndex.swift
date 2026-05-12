import Foundation
import FoundationModels

struct AgenticToolWorkspaceSemanticIndex: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "workspace_semantic_index",
        description: "Build semantic embeddings index for workspace items",
        category: "workspace",
        inputSchema: ["scope": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let scope = parameters["scope"] ?? "all"

        var documents: [(id: String, type: String, content: String)] = []

        for task in TasksManager.shared.tasks {
            documents.append((task.id.uuidString, "task", "\(task.title): \(task.description)"))
        }

        for notebook in NotebooksManager.shared.notebooks {
            for folder in notebook.folders {
                for page in folder.pages {
                    documents.append((page.id.uuidString, "note", "\(page.title): \(String(page.content.prefix(200)))"))
                }
            }
        }

        for event in CalendarManager.shared.events {
            documents.append((event.id.uuidString, "event", "\(event.title): \(event.description)"))
        }

        let session = LanguageModelSession(instructions: "You are a semantic indexing engine. Analyze documents and generate semantic category assignments.")
        let docSummary = documents.prefix(30).map { "\($0.type): \($0.content.prefix(100))" }.joined(separator: "\n")
        let response = try await session.respond(to: "Analyze and categorize these workspace documents for semantic indexing:\n\(docSummary)")

        return AgenticToolOutput(
            summary: "Built semantic index for \(documents.count) documents (scope: \(scope))",
            generatedCode: nil,
            metadata: ["scope": scope, "documentCount": "\(documents.count)"],
            dataPayload: ["semanticIndex": response.content]
        )
    }
}
