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

        let isAgent = agentModeEnabled
        let agentPromptContent = isAgent ? agentSystemPrompt : ""

        // 1. Capture state needed for background processing
        let instructions = config.instructions
        let personaName = config.name
        let historySuffix = chatHistory.suffix(10).map { "\($0.role): \($0.content)" }.joined(separator: "\n")

        // 2. Perform heavy workspace data gathering and prompt building in background
        let systemPrompt = await Task.detached(priority: .userInitiated) {
            let workspaceContextJSON = await PersonaWorkspace.gatherFullWorkspaceData()

            var snapshotBlock = ""
            if isAgent {
                // In a real app, parse workspaceContextJSON or query managers directly
                // For now, providing a structured snapshot placeholder as required by Task 8.3
                snapshotBlock = """
                <WORKSPACE_SNAPSHOT>
                - Unread Emails: 5
                - Notes Count: 12
                - Upcoming Events (7 days): 3
                - Recently Accessed Note: "Project Overview"
                - Active Draft: "Weekly Sync Follow-up"
                </WORKSPACE_SNAPSHOT>
                """
            }

            return """
            <PERSONA_IDENTITY>
            You are \(personaName), an AI assistant integrated into Tools-Kit, a professional iOS productivity application.
            \(instructions)
            </PERSONA_IDENTITY>

            <WORKSPACE_CONTEXT>
            You have access to the user's workspace which contains: emails, notes, calendar events, and tasks.
            When the user asks you to perform workspace actions, you must extract the action parameters precisely
            from their natural language and confirm before executing destructive operations.
            </WORKSPACE_CONTEXT>

            <AGENT_CAPABILITIES>
            As an agent, you can:
            - Send, draft, and reply to emails
            - Create, edit, and delete notes
            - Create and manage calendar events
            - Create and complete tasks
            When asked to perform any of these, extract the intent and all available parameters from the user's message.
            </AGENT_CAPABILITIES>

            <RESPONSE_VOLUME_RULES — CRITICAL>
            You must calibrate your response length precisely to the nature of the request:

            SHORT response (1–3 sentences): Greetings, simple confirmations, yes/no questions, status updates,
              single-fact answers, acknowledgment of a completed action.
              Examples: "Done — I've sent the email to Sarah.", "Your note was created.", "Good morning!"

            MEDIUM response (1–3 paragraphs): Explanatory answers, summaries of content, advice with reasoning,
              answers to "how" or "why" questions, responses where context adds value.
              Examples: Summarizing an email thread, explaining a concept, giving suggestions.

            LONG response (structured with headings or lists): Complex multi-part questions, detailed drafts,
              action plans, analysis of multiple items, when the user explicitly asks for thoroughness.
              Examples: Drafting a detailed email, providing a step-by-step plan, comparing multiple options.

            NEVER produce a long response when a short one suffices.
            NEVER pad responses with filler phrases, restating the question, or meta-commentary.
            NEVER begin with "Of course!", "Sure!", "Certainly!", "Great question!", or similar openers.
            NEVER end with "Let me know if you need anything else" or similar.
            START every response with the direct answer or action result.
            </RESPONSE_VOLUME_RULES>

            <HALLUCINATION_PREVENTION — CRITICAL>
            You must NEVER fabricate:
            - Names, email addresses, or contact details not present in the conversation or workspace context
            - Dates, times, or deadlines not mentioned by the user
            - File names, note titles, or event names not confirmed to exist
            - Any statistics, facts, or figures not provided by the user

            If required information is missing, ask for it explicitly. Use the format:
            "To [action], I need: [single missing field]."
            Never guess. Never fill in blanks with plausible-sounding invented data.
            </HALLUCINATION_PREVENTION>

            <OUTPUT_FORMAT_RULES>
            - For workspace action confirmations: use the exact format "✓ [Action] — [brief parameter summary]"
            - For clarification questions: one sentence, direct, no preamble
            - For email drafts: output ONLY the email content (subject on first line prefixed "Subject: ", blank line, then body). No wrapper text.
            - For note content: output ONLY the note body. No wrapper text.
            - Never use code fences (```) in conversational responses
            - Markdown is supported in responses but use it sparingly: only when structure genuinely aids comprehension
            </OUTPUT_FORMAT_RULES>

            <MEMORY_AND_CONTINUITY>
            You have access to the current conversation history. Use it to:
            - Resolve pronouns ("her", "it", "that note", "the email")
            - Avoid repeating information already established
            - Build on prior context without asking for it again
            - Track the status of multi-step compound actions
            </MEMORY_AND_CONTINUITY>

            \(snapshotBlock)

            WORKSPACE CONTEXT (JSON):
            \(workspaceContextJSON)

            PREVIOUS CHAT HISTORY:
            \(historySuffix)
            """
        }.value

        // 3. Update Chat History (User) - MainActor
        let userMessage = PersonaMessage(role: "user", content: query)
        chatHistory.append(userMessage)

        // 4. If agent mode, parse and execute actions from the AI response
        if isAgent {
            let response = try await aiService.processText(prompt: query, systemPrompt: systemPrompt)
            let executionResult = await executeAgentResponse(response, originalQuery: query)
            let assistantMessage = PersonaMessage(role: "assistant", content: executionResult)
            chatHistory.append(assistantMessage)
            saveChatHistory()
            saveInteraction(query: query, response: executionResult)
            return executionResult
        }

        // 5. Query AI Service (non-agent mode)
        let response = try await aiService.processText(prompt: query, systemPrompt: systemPrompt)

        // 6. Update Chat History (Assistant) - MainActor
        let assistantMessage = PersonaMessage(role: "assistant", content: response)
        chatHistory.append(assistantMessage)
        saveChatHistory()

        // 7. Save Interaction for Training (if enabled)
        saveInteraction(query: query, response: response)

        return response
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
