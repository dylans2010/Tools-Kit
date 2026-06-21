import Foundation

actor SystemAgent {
    private let aiService: AIService
    private let toolRouter: SystemAgentToolRouter
    private let maxToolIterations = 10

    private(set) var history: [SystemAgentMessage] = []
    private(set) var currentState: SystemAgentState = .idle

    private var stateContinuation: AsyncStream<SystemAgentState>.Continuation?
    private var stateStreamValue: AsyncStream<SystemAgentState>?
    private var historyContinuation: AsyncStream<[SystemAgentMessage]>.Continuation?
    private var historyStreamValue: AsyncStream<[SystemAgentMessage]>?

    init(aiService: AIService, toolRouter: SystemAgentToolRouter = SystemAgentToolRouter()) {
        self.aiService = aiService
        self.toolRouter = toolRouter
    }

    func stateStream() -> AsyncStream<SystemAgentState> {
        if let stateStreamValue {
            return stateStreamValue
        }

        let stream = AsyncStream<SystemAgentState> { continuation in
            self.stateContinuation = continuation
            continuation.yield(self.currentState)
        }
        stateStreamValue = stream
        return stream
    }

    func historyStream() -> AsyncStream<[SystemAgentMessage]> {
        if let historyStreamValue {
            return historyStreamValue
        }

        let stream = AsyncStream<[SystemAgentMessage]> { continuation in
            self.historyContinuation = continuation
            continuation.yield(self.history)
        }
        historyStreamValue = stream
        return stream
    }

    func sendMessage(_ content: String) async throws -> SystemAgentMessage {
        try Task.checkCancellation()
        let userMessage = SystemAgentMessage(role: .user, content: content)
        appendToHistory(userMessage)

        do {
            try await transition(to: .thinking)
            let responseText = try await requestModelResponse()

            try await transition(to: .responding)
            let assistant = SystemAgentMessage(role: .assistant, content: responseText)
            appendToHistory(assistant)
            try await transition(to: .completed)
            return assistant
        } catch let error as SystemAgentError {
            appendToHistory(SystemAgentMessage(role: .failed(message: error.localizedDescription), content: error.localizedDescription))
            try await transition(to: .failed(error))
            throw error
        } catch {
            let wrapped = SystemAgentError.aiServiceFailure(underlying: error)
            appendToHistory(SystemAgentMessage(role: .failed(message: wrapped.localizedDescription), content: wrapped.localizedDescription))
            try await transition(to: .failed(wrapped))
            throw wrapped
        }
    }

    func resetSession() {
        history = []
        currentState = .idle
        stateContinuation?.yield(.idle)
        historyContinuation?.yield([])
    }

    private func transition(to state: SystemAgentState) async throws {
        currentState = state
        stateContinuation?.yield(state)
    }

    private func requestModelResponse() async throws -> String {
        let transcript = history.map(\.chatMessage)
        let prompt = buildLoopPrompt(from: transcript)
        let response = try await aiService.processText(
            prompt: prompt,
            systemPrompt: buildSystemPromptWithTools(),
            model: nil
        )
        guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SystemAgentError.emptyResponse
        }
        return response
    }

    private func parseAgentEnvelope(from content: String) -> (toolCall: (name: String, input: [String: Any])?, finalText: String?) {
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (nil, cleaned)
        }

        if let tool = object["tool"] as? String {
            return ((tool, object["input"] as? [String: Any] ?? [:]), nil)
        }

        if let final = object["final"] as? String {
            return (nil, final)
        }

        return (nil, cleaned)
    }

    private func appendToHistory(_ message: SystemAgentMessage) {
        history.append(message)
        historyContinuation?.yield(history)
    }

    private func buildSystemPromptWithTools() -> String {
        var baseInstructions = ""
        if let url = Bundle.main.url(forResource: "FoundationModelsSystem", withExtension: "md"),
           let content = try? String(contentsOf: url) {
            baseInstructions = content
        } else {
            baseInstructions = "You are a helpful AI assistant powered by Foundation Models."
        }

        let skillsPrompt = AIService.SkillsManager.shared.activeSkillsPrompt()

        return """
        \(baseInstructions)

        \(skillsPrompt)
        """
    }

    private func buildLoopPrompt(from transcript: [ChatMessage]) -> String {
        let rendered = transcript.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        return """
        Continue this conversation and decide the next action:
        \(rendered)
        """
    }
}
