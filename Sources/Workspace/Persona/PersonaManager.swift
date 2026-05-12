import Foundation
import SwiftUI

/// Manages the AI Persona based on workspace data.
@MainActor
final class PersonaManager: ObservableObject {
    nonisolated(unsafe) static let shared = PersonaManager()

    @Published var interactions: [PersonaInteraction] = []
    @Published var chatHistory: [PersonaMessage] = []
    @Published var config: PersonaConfig = PersonaConfig(name: "Expert Assistant", instructions: "You are an expert AI Persona.", baseModel: "gpt-4", workspaceScope: ["All"])
    @Published var isThinking: Bool = false

    private let dataStore = UnifiedDataStore.shared
    private let aiService = AIService.shared

    private init() {
        self.interactions = dataStore.personaInteractions
        // Load chat history from disk if exists
        if let data = try? dataStore.load([PersonaMessage].self, key: "persona_chat_history") {
            self.chatHistory = data
        }
        if let savedConfig = try? dataStore.load(PersonaConfig.self, key: "persona_config") {
            self.config = savedConfig
        }
    }

    func queryPersona(query: String) async throws -> String {
        isThinking = true
        defer { isThinking = false }

        // 1. Gather Full Context
        let workspaceContext = PersonaWorkspace.gatherFullWorkspaceData()

        // 2. Build High-Complex Training Prompt
        let systemPrompt = """
        \(config.instructions)

        PERSONALITY & BEHAVIOR:
        - You are a highly sophisticated AI Persona integrated into the user's Workspace.
        - You have access to the user's full data (Mail, Calendar, Tasks, Notes, etc.).
        - Your goal is to provide deeply personalized, actionable, and expert-level assistance.
        - Analyze the provided Workspace JSON context to answer questions accurately.
        - If the user asks about their schedule, look at 'calendar_events'.
        - If they ask about emails, refer to 'mail_accounts'.
        - Be concise but thorough. Use professional yet approachable tone.
        - Respond using rich Markdown formatting (headers, lists, bold text, etc.).

        WORKSPACE CONTEXT (JSON):
        \(workspaceContext)

        PREVIOUS CHAT HISTORY:
        \(chatHistory.suffix(10).map { "\($0.role): \($0.content)" }.joined(separator: "\n"))
        """

        // 3. Update Chat History (User)
        let userMessage = PersonaMessage(role: "user", content: query)
        chatHistory.append(userMessage)

        // 4. Query AI Service
        let response = try await aiService.processText(prompt: query, systemPrompt: systemPrompt)

        // 5. Update Chat History (Assistant)
        let assistantMessage = PersonaMessage(role: "assistant", content: response)
        chatHistory.append(assistantMessage)
        saveChatHistory()

        // 6. Save Interaction for Training (if enabled)
        if config.isTrainingEnabled {
            let trainingEntry = PersonaModelTraining(userQuery: query, aiResponse: response)
            try? dataStore.save(trainingEntry, key: "persona_training_\(trainingEntry.id.uuidString)")
        }

        // 7. Legacy Compatibility
        let interaction = PersonaInteraction(
            query: query,
            response: response,
            contextUsed: ["full_workspace_context"]
        )
        interactions.append(interaction)
        try? dataStore.savePersonaInteraction(interaction)

        return response
    }



    func queryPersonaSafely(query: String) async {
        do {
            _ = try await queryPersona(query: query)
        } catch {
            let fallback = PersonaMessage(role: "assistant", content: "I couldn't complete that request right now. Please check your AI provider configuration and try again.\n\nError: `\(error.localizedDescription)`")
            chatHistory.append(fallback)
            saveChatHistory()
        }
    }

    func saveChatHistory() {
        try? dataStore.save(chatHistory, key: "persona_chat_history")
    }

    func saveConfig() {
        try? dataStore.save(config, key: "persona_config")
    }

    func clearHistory() {
        chatHistory.removeAll()
        saveChatHistory()
    }


    /// Legacy compatibility API used by Workspace SDK wrappers.
    func recentMemories(limit: Int? = nil) -> [PersonaInteraction] {
        let history = interactions
        guard let limit else { return history }
        return Array(history.suffix(max(0, limit)))
    }

    /// Legacy compatibility API used by Workspace SDK wrappers.
    func injectMemory(entityID: UUID, content: String) {
        let memory = PersonaInteraction(query: "Memory Injection [\(entityID.uuidString)]", response: content, contextUsed: ["manual_memory_injection"])
        interactions.append(memory)
        try? dataStore.savePersonaInteraction(memory)
    }

}
