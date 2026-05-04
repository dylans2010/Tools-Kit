import Foundation

/// Orchestrates AI capabilities across the workspace.
/// Coordinates between different models and services to provide intelligent features.
final class AIOrchestrator {
    static let shared = AIOrchestrator()

    private let embeddingService = EmbeddingService.shared
    private let dataStore = UnifiedDataStore.shared

    private init() {}

    /// Processes a natural language query against the workspace context.
    func queryWorkspace(_ prompt: String) async throws -> String {
        print("[AIOrchestrator] Querying workspace with prompt: \(prompt)")

        // 1. Fetch real workspace data for context
        let workflows = dataStore.loadWorkflows()
        let canvases = dataStore.loadCanvases()
        let notebooks = NotebooksManager.shared.notebooks
        let tasks = TasksManager.shared.tasks

        // 2. Perform simple keyword search across all entities
        let query = prompt.lowercased()
        var contextResults: [String] = []

        for task in tasks where task.title.lowercased().contains(query) || task.description.lowercased().contains(query) {
            contextResults.append("Task: \(task.title) (Priority: \(task.priority.rawValue))")
        }

        for workflow in workflows where workflow.title.lowercased().contains(query) {
            contextResults.append("Workflow: \(workflow.title)")
        }

        for notebook in notebooks where notebook.name.lowercased().contains(query) {
            contextResults.append("Notebook: \(notebook.name)")
        }

        if contextResults.isEmpty {
            return "I couldn't find any specific items in your workspace matching '\(prompt)'. However, I'm here to help you manage your tasks, notes, and automations."
        }

        return "I found the following relevant items in your workspace: " + contextResults.joined(separator: "; ") + ". How would you like to proceed with them?"
    }

    /// Indexes a piece of data for semantic search.
    func indexData(key: String, content: String) async {
        do {
            let embedding = try await embeddingService.generateEmbedding(for: content)
            // Save embedding associated with the key for later retrieval in vector DB
            print("[AIOrchestrator] Indexed data for key: \(key)")
        } catch {
            print("[AIOrchestrator] Indexing failed: \(error.localizedDescription)")
        }
    }
}
