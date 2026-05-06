import Foundation

/// Manages the AI Persona based on workspace data.
final class PersonaManager: ObservableObject {
    static let shared = PersonaManager()

    @Published var interactions: [PersonaInteraction] = []

    private let dataStore = UnifiedDataStore.shared
    private let aiService = AIService.shared

    private init() {
        self.interactions = dataStore.personaInteractions
    }

    func queryPersona(query: String) async throws -> String {
        // 1. Gather Context
        let context = buildWorkspaceContext()

        // 2. Query AI Service
        let response = try await aiService.generateResponse(prompt: query)

        // 3. Save Interaction
        let interaction = PersonaInteraction(
            query: query,
            response: response,
            contextUsed: ["workspace_index"]
        )
        interactions.append(interaction)
        try dataStore.savePersonaInteraction(interaction)

        return response
    }

    func recentMemories() -> [PersonaInteraction] {
        return Array(interactions.suffix(20))
    }

    func injectMemory(entityID: UUID, content: String) {
        let interaction = PersonaInteraction(
            query: "[Memory Injection] \(entityID)",
            response: content,
            contextUsed: [entityID.uuidString]
        )
        interactions.append(interaction)
        try? dataStore.savePersonaInteraction(interaction)
    }

    private func buildWorkspaceContext() -> String {
        let notebooks = NotebooksManager.shared.notebooks.map { $0.name }.joined(separator: ", ")
        let tasks = TasksManager.shared.todayTasks.map { $0.title }.joined(separator: ", ")
        return "Workspace Context: Notebooks: [\(notebooks)]. Tasks: [\(tasks)]."
    }
}
