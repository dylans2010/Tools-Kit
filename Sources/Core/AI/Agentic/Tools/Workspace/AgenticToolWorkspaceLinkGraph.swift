import Foundation

struct AgenticToolWorkspaceLinkGraph: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "workspace_link_graph",
        description: "Build a link graph between workspace items",
        category: "workspace",
        inputSchema: ["rootId": "String", "depth": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let rootId = parameters["rootId"] ?? ""
        let depthStr = parameters["depth"] ?? "2"
        let depth = Int(depthStr) ?? 2

        var nodes: [String] = []
        var edges: [(String, String)] = []

        let tasks = TasksManager.shared.tasks
        let events = CalendarManager.shared.events

        for task in tasks.prefix(20) {
            nodes.append("task:\(task.title)")
            for event in events {
                if event.title.lowercased().contains(task.title.lowercased().prefix(10)) {
                    edges.append(("task:\(task.title)", "event:\(event.title)"))
                }
            }
        }

        for notebook in NotebooksManager.shared.notebooks.prefix(5) {
            nodes.append("notebook:\(notebook.name)")
            for folder in notebook.folders {
                for page in folder.pages.prefix(5) {
                    nodes.append("note:\(page.title)")
                    edges.append(("notebook:\(notebook.name)", "note:\(page.title)"))
                }
            }
        }

        var payload: [String: String] = [
            "nodeCount": "\(nodes.count)",
            "edgeCount": "\(edges.count)"
        ]
        for (index, edge) in edges.prefix(20).enumerated() {
            payload["edge_\(index)"] = "\(edge.0) → \(edge.1)"
        }

        return AgenticToolOutput(
            summary: "Built link graph with \(nodes.count) nodes and \(edges.count) edges (depth \(depth))",
            generatedCode: nil,
            metadata: ["rootId": rootId, "depth": depthStr, "nodeCount": "\(nodes.count)"],
            dataPayload: payload
        )
    }
}
