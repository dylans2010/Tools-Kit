import Foundation
import SwiftUI

/// Manages the AI Persona based on workspace data.
@MainActor
final class PersonaManager: ObservableObject {
    static let shared = PersonaManager()

    @Published var interactions: [PersonaInteraction] = []
    @Published var chatHistory: [PersonaMessage] = []
    @Published var chatThreads: [PersonaChatThread] = []
    @Published var activeThread: PersonaChatThread?

    var threads: [PersonaChatThread] {
        get { chatThreads }
        set { chatThreads = newValue }
    }
    @Published var config: PersonaConfig = PersonaConfig(name: "Expert Assistant", instructions: "You are an expert AI Persona.", baseModel: "gpt-4", workspaceScope: ["All"])
    @Published var isThinking: Bool = false
    @Published var agentModeEnabled: Bool = false

    private let dataStore = UnifiedDataStore.shared
    private let aiService = AIService.shared
    private let mcpBridge = MCPPersonaBridge()

    private var agentSystemPromptCache: String?

    var agentSystemPrompt: String {
        if let cached = agentSystemPromptCache { return cached }
        if let url = Bundle.main.url(forResource: "AgentPersonaSystem", withExtension: "md"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            agentSystemPromptCache = content
            return content
        }
        return ""
    }

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

        // 1. Capture state needed for background processing
        let creativity = config.creativity
        let formality = config.formality
        let humor = config.humor
        let temperature = config.temperature
        let maxTokens = config.maxTokens
        let mcpEnabled = config.mcpToolsEnabled
        let historySuffix = chatHistory.suffix(10).map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        let basePrompt = agentSystemPrompt

        // 2. Perform heavy workspace data gathering and prompt building in background
        let systemPrompt = await Task.detached(priority: .userInitiated) {
            let workspaceContextJSON = await PersonaWorkspace.gatherFullWorkspaceData()
            let mcpContext = mcpEnabled ? await MainActor.run { MCPPersonaBridge().connectedServersContext() } : "No MCP servers connected."

            var prompt = basePrompt
            prompt = prompt.replacingOccurrences(of: "{{creativity}}", with: String(format: "%.1f", creativity))
            prompt = prompt.replacingOccurrences(of: "{{formality}}", with: String(format: "%.1f", formality))
            prompt = prompt.replacingOccurrences(of: "{{humor}}", with: String(format: "%.1f", humor))
            prompt = prompt.replacingOccurrences(of: "{{temperature}}", with: String(format: "%.1f", temperature))
            prompt = prompt.replacingOccurrences(of: "{{maxTokens}}", with: "\(maxTokens)")
            prompt = prompt.replacingOccurrences(of: "{{workspace_context}}", with: workspaceContextJSON)
            prompt = prompt.replacingOccurrences(of: "{{mcp_context}}", with: mcpContext)
            prompt = prompt.replacingOccurrences(of: "{{chat_history}}", with: historySuffix)
            prompt = prompt.replacingOccurrences(of: "{{user_query}}", with: query)

            return prompt
        }.value

        // 3. Update Chat History (User) - MainActor
        let userMessage = PersonaMessage(role: "user", content: query)
        chatHistory.append(userMessage)

        // 4. Query AI Service with tuning parameters
        let response = try await aiService.processText(prompt: query, systemPrompt: systemPrompt)

        // 5. Handle MCP Tool Calls (Pattern: [MCP: server -> tool] result)
        let executionResult = await handleMCPInResponse(response, originalQuery: query)

        // 6. Update Chat History (Assistant) - MainActor
        let assistantMessage = PersonaMessage(role: "assistant", content: executionResult)
        chatHistory.append(assistantMessage)
        saveChatHistory()

        // 7. Save Interaction for Training (if enabled)
        saveInteraction(query: query, response: executionResult)

        return executionResult
    }

    private func handleMCPInResponse(_ response: String, originalQuery: String) async -> String {
        let agentActions = PersonaAgentFramework.parseAgentActions(from: response)
        if agentActions.isEmpty { return response }

        return await executeAgentResponse(response, originalQuery: originalQuery)
    }

    private func saveInteraction(query: String, response: String) {
        if config.isTrainingEnabled {
            let trainingEntry = PersonaModelTraining(userQuery: query, aiResponse: response)
            try? dataStore.save(trainingEntry, key: "persona_training_\(trainingEntry.id.uuidString)")
        }
        let interaction = PersonaInteraction(
            query: query,
            response: response,
            contextUsed: ["full_workspace_context"]
        )
        interactions.append(interaction)
        try? dataStore.savePersonaInteraction(interaction)
    }

    private func executeAgentResponse(_ aiResponse: String, originalQuery: String) async -> String {
        let actions = PersonaAgentFramework.parseAgentActions(from: aiResponse)
        if actions.isEmpty {
            return aiResponse
        }

        var results: [String] = []
        for action in actions {
            do {
                let result = try await PersonaAgentFramework.shared.execute(action)
                switch result {
                case .success(let payload):
                    switch payload {
                    case .message(let msg):
                        results.append(msg)
                    case .itemSnapshot(let snapshot):
                        results.append("Created \(snapshot.type.rawValue): **\(snapshot.title)** (id: `\(snapshot.id)`)")
                    case .itemSummaries(let summaries):
                        let listing = summaries.prefix(10).map { "- \($0.type.rawValue): \($0.title)" }.joined(separator: "\n")
                        results.append("Found \(summaries.count) item(s):\n\(listing)")
                    }
                case .failure(let error):
                    results.append("Action failed: \(error.localizedDescription)")
                }
            } catch {
                results.append("Error: \(error.localizedDescription)")
            }
        }

        let actionSummary = results.joined(separator: "\n\n")
        let naturalParts = aiResponse.components(separatedBy: "[ACTION:")
        let preamble = naturalParts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if preamble.isEmpty {
            return actionSummary
        }
        return "\(preamble)\n\n\(actionSummary)"
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

    func recentMemories(limit: Int? = nil) -> [PersonaInteraction] {
        let history = interactions
        guard let limit = limit else { return history }
        return Array(history.suffix(max(0, limit)))
    }

    func injectMemory(entityID: UUID, content: String) {
        let memory = PersonaInteraction(query: "Memory Injection [\(entityID.uuidString)]", response: content, contextUsed: ["manual_memory_injection"])
        interactions.append(memory)
        try? dataStore.savePersonaInteraction(memory)
    }
}
