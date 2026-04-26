import Foundation

actor SystemAgent {
    private let aiService: AIService
    private let toolRouter: SystemAgentToolRouter
    private let maxToolIterations = 10

    private(set) var history: [SystemAgentMessage] = []
    private(set) var currentState: SystemAgentState = .idle

    private var stateContinuation: AsyncStream<SystemAgentState>.Continuation?
    private var stateStreamValue: AsyncStream<SystemAgentState>?

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

    func sendMessage(_ content: String) async throws -> SystemAgentMessage {
        try Task.checkCancellation()
        print("[SystemAgent] sendMessage started")
        let userMessage = SystemAgentMessage(role: .user, content: content)
        history.append(userMessage)

        do {
            try await transition(to: .thinking)
            var loopCount = 0

            while loopCount < maxToolIterations {
                let responseText = try await requestModelResponse()
                let parsed = try parseAgentEnvelope(from: responseText)

                if let toolName = parsed.toolName {
                    try await transition(to: .executingTool(toolName))
                    let toolInput = parsed.toolInput ?? [:]
                    let toolCall = SystemAgentMessage.ToolCall(name: toolName, input: toolInput)
                    let toolResult = try await toolRouter.route(toolName: toolName, input: toolInput)
                    history.append(SystemAgentMessage(role: .tool, content: toolResult, toolCalls: [toolCall]))
                    loopCount += 1
                    print("[SystemAgent] executed tool \(toolName)")
                    continue
                }

                guard let final = parsed.finalText?.trimmingCharacters(in: .whitespacesAndNewlines), !final.isEmpty else {
                    throw SystemAgentError.emptyResponse
                }

                try await transition(to: .responding)
                let assistant = SystemAgentMessage(role: .assistant, content: final)
                history.append(assistant)
                try await transition(to: .idle)
                print("[SystemAgent] sendMessage completed")
                return assistant
            }

            throw SystemAgentError.maxToolIterationsReached(limit: maxToolIterations)
        } catch let error as SystemAgentError {
            try await transition(to: .failed(error))
            throw error
        } catch {
            let wrapped = SystemAgentError.aiServiceFailure(underlying: error)
            try await transition(to: .failed(wrapped))
            throw wrapped
        }
    }

    func resetSession() {
        history = []
        currentState = .idle
        stateContinuation?.yield(.idle)
    }

    private func transition(to state: SystemAgentState) async throws {
        currentState = state
        stateContinuation?.yield(state)
    }

    private func requestModelResponse() async throws -> String {
        let toolsPayload = toolRouter.toolDefinitions.map { tool in
            [
                "name": tool.name,
                "description": tool.description,
                "inputSchema": tool.inputSchema.mapValues { $0.value }
            ] as [String: Any]
        }

        let transcript = history.map { "[\($0.role.rawValue)] \($0.content)" }.joined(separator: "\n")
        let prompt = """
        Available tools: \(toolsPayload)

        Conversation:
        \(transcript)

        Respond ONLY as compact JSON with either:
        {"tool":"<tool_name>","input":{...}}
        OR
        {"final":"<assistant_text>"}
        """

        print("[SystemAgent] requesting AI response")
        let response = try await aiService.processText(
            prompt: prompt,
            systemPrompt: "You are a helpful system agent. You have access to tools to help the user accomplish tasks on their device.",
            model: nil
        )
        guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SystemAgentError.emptyResponse
        }
        print("[SystemAgent] AI response received")
        return response
    }

    private func parseAgentEnvelope(from content: String) throws -> (toolName: String?, toolInput: [String: Any]?, finalText: String?) {
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (nil, nil, cleaned)
        }

        if let tool = object["tool"] as? String {
            return (tool, object["input"] as? [String: Any] ?? [:], nil)
        }

        if let final = object["final"] as? String {
            return (nil, nil, final)
        }

        throw SystemAgentError.emptyResponse
    }
}
