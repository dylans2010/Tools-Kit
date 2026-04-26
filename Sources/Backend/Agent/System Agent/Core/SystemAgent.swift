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
            for _ in 0..<maxToolIterations {
                let responseText = try await requestModelResponse()
                let parsed = parseAgentEnvelope(from: responseText)

                if let toolCall = parsed.toolCall {
                    try await transition(to: .executingTool(name: toolCall.name))
                    let callMessage = SystemAgentMessage(
                        role: .toolCall(name: toolCall.name, input: toolCall.input.mapValues(AnyCodable.init)),
                        content: "⚙ Running: \(toolCall.name)"
                    )
                    appendToHistory(callMessage)

                    let toolResult = try await toolRouter.route(toolName: toolCall.name, input: toolCall.input)
                    appendToHistory(SystemAgentMessage(
                        role: .toolResult(toolName: toolCall.name, result: toolResult),
                        content: toolResult
                    ))
                    try await transition(to: .thinking)
                    continue
                }

                if let finalText = parsed.finalText?.trimmingCharacters(in: .whitespacesAndNewlines), !finalText.isEmpty {
                    try await transition(to: .responding)
                    let assistant = SystemAgentMessage(role: .assistant, content: finalText)
                    appendToHistory(assistant)
                    try await transition(to: .completed)
                    return assistant
                }

                throw SystemAgentError.emptyResponse
            }

            throw SystemAgentError.maxToolIterationsReached(limit: maxToolIterations, message: "Agent reached maximum tool call iterations without producing a final response")
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
        let definitions = toolRouter.toolDefinitions.compactMap { tool -> String? in
            guard let schemaObject = try? JSONSerialization.data(
                withJSONObject: tool.inputSchema.mapValues(\.value),
                options: [.sortedKeys]
            ), let schema = String(data: schemaObject, encoding: .utf8) else {
                return nil
            }
            return "- \(tool.name): \(tool.description)\n  schema: \(schema)"
        }.joined(separator: "\n")

        return """
        You are a system agent with access to the following tools. When you need to use a tool, respond ONLY with a JSON object in this exact format and nothing else:
        {"tool":"<tool_name>","input":{"<param>":"<value>"}}

        When you have enough information to answer without a tool, respond with:
        {"final":"<assistant_text>"}

        Available tools:
        \(definitions)
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
