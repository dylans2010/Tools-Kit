import Foundation
import FoundationModels

struct AgenticToolNoteGraphLinker: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "note_graph_linker",
        description: "Link related notes into a knowledge graph",
        category: "notes",
        inputSchema: ["scope": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let scope = parameters["scope"] ?? "all"
        let manager = NotebooksManager.shared

        var allPages: [(id: String, title: String, content: String)] = []
        for notebook in manager.notebooks {
            if scope != "all" && notebook.name.lowercased() != scope.lowercased() { continue }
            for folder in notebook.folders {
                for page in folder.pages {
                    allPages.append((page.id.uuidString, page.title, String(page.content.prefix(200))))
                }
            }
        }

        let pageDescriptions = allPages.prefix(30).map { "[\($0.id)] \($0.title): \($0.content.prefix(100))" }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a knowledge graph builder. Identify semantic relationships between notes and output linked pairs.")
        let response = try await session.respond(to: "Analyze these notes and identify relationships:\n\n\(pageDescriptions)")

        return AgenticToolOutput(
            summary: "Built knowledge graph with \(allPages.count) nodes in scope '\(scope)'",
            generatedCode: nil,
            metadata: ["scope": scope, "nodeCount": "\(allPages.count)"],
            dataPayload: ["graph": response.content]
        )
    }
}
