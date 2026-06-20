import Foundation
import os

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class AgenticCoreSessionManager: ObservableObject {
    static let shared = AgenticCoreSessionManager()

    @Published var tokens: [AgenticStreamToken] = []
    @Published var isStreaming: Bool = false
    @Published var currentResponse: String = ""
    @Published var executionSteps: [AgenticExecutionStep] = []
    @Published var diagnostics: [AgenticDiagnostic] = []

    private let logger = Logger(subsystem: "com.toolskit.agentic", category: "session-manager")
    private let availabilityChecker = AgenticFoundationModelsAvailabilityChecker.shared

    private init() {}

    // MARK: - Streaming Session

    func streamResponse(prompt: String, systemContext: String, tools: [AgenticToolDefinition]) async throws -> String {
        isStreaming = true
        currentResponse = ""
        tokens = []
        defer { isStreaming = false }

        addDiagnostic(level: .info, message: "Starting streaming session", component: "SessionManager")

        let status = await availabilityChecker.checkFullAvailability()

        #if canImport(FoundationModels)
        if status.isFrameworkAvailable && status.isRuntimeAvailable {
            if #available(iOS 17.0, macOS 14.0, *) {
                return try await streamWithFoundationModels(prompt: prompt, systemContext: systemContext, tools: tools)
            }
        }
        #endif

        return try await streamWithAIService(prompt: prompt, systemContext: systemContext, tools: tools)
    }

    #if canImport(FoundationModels)
    @available(iOS 17.0, macOS 14.0, *)
    private func streamWithFoundationModels(prompt: String, systemContext: String, tools: [AgenticToolDefinition]) async throws -> String {
        addDiagnostic(level: .info, message: "Initializing LanguageModelSession", component: "SessionManager")

        let session = LanguageModelSession(instructions: systemContext)

        let toolContext = formatToolContext(tools: tools)
        let fullPrompt = """
        Available workspace tools:
        \(toolContext)

        User request: \(prompt)

        Analyze the workspace and respond with reasoning and any tool actions needed.
        """

        addDiagnostic(level: .info, message: "Starting token stream", component: "SessionManager")

        let stream = session.streamResponse(to: fullPrompt)
        var fullResponse = ""

        for try await partial in stream {
            let newContent = partial.content
            if newContent.count > fullResponse.count {
                let delta = String(newContent.dropFirst(fullResponse.count))
                let token = AgenticStreamToken(content: delta, tokenType: classifyToken(delta))
                tokens.append(token)
                fullResponse = newContent
                currentResponse = fullResponse
            }
        }

        addDiagnostic(level: .success, message: "Stream completed: \(tokens.count) tokens", component: "SessionManager")
        return fullResponse
    }
    #endif

    private func streamWithAIService(prompt: String, systemContext: String, tools: [AgenticToolDefinition]) async throws -> String {
        addDiagnostic(level: .info, message: "Foundation Models unavailable, falling back to AIService", component: "SessionManager")

        let toolContext = formatToolContext(tools: tools)
        let fullSystemPrompt = """
        \(systemContext)

        Available workspace tools:
        \(toolContext)
        """

        let fullPrompt = """
        User request: \(prompt)

        Analyze the workspace and respond with reasoning and any tool actions needed.
        """

        let response = try await AIService.shared.processText(
            prompt: fullPrompt,
            systemPrompt: fullSystemPrompt
        )

        // Simulate streaming for UI consistency
        let words = response.components(separatedBy: " ")
        var accumulated = ""

        for (index, word) in words.enumerated() {
            let space = index == 0 ? "" : " "
            let delta = space + word
            accumulated += delta

            let token = AgenticStreamToken(content: delta, tokenType: classifyToken(delta))
            tokens.append(token)
            currentResponse = accumulated

            // Minimal delay to simulate streaming feel
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        addDiagnostic(level: .success, message: "AIService fallback completed", component: "SessionManager")
        return response
    }

    // MARK: - Execution Tracking

    func recordStep(action: String, toolName: String? = nil, input: String? = nil) -> String {
        let step = AgenticExecutionStep(
            action: action,
            toolName: toolName,
            input: input,
            status: .running
        )
        executionSteps.append(step)
        return step.id
    }

    func completeStep(id: String, output: String?, success: Bool) {
        if let index = executionSteps.firstIndex(where: { $0.id == id }) {
            let existing = executionSteps[index]
            executionSteps[index] = AgenticExecutionStep(
                id: existing.id,
                action: existing.action,
                toolName: existing.toolName,
                input: existing.input,
                output: output,
                status: success ? .completed : .failed,
                startedAt: existing.startedAt,
                completedAt: Date()
            )
        }
    }

    // MARK: - Diagnostics

    func addDiagnostic(level: AgenticDiagnostic.DiagnosticLevel, message: String, component: String) {
        let diagnostic = AgenticDiagnostic(level: level, message: message, component: component)
        diagnostics.append(diagnostic)
        logger.log(level: level == .error ? .error : .info, "\(component): \(message)")
    }

    func clearSession() {
        tokens = []
        currentResponse = ""
        executionSteps = []
        diagnostics = []
        isStreaming = false
    }

    // MARK: - Helpers

    private func formatToolContext(tools: [AgenticToolDefinition]) -> String {
        guard !tools.isEmpty else { return "No workspace tools available." }

        return tools.map { tool in
            let params = tool.parameters.map { "\($0.name): \($0.type)\($0.required ? " (required)" : "")" }.joined(separator: ", ")
            return "- \(tool.name): \(tool.description) [\(params)] (derived from: \(tool.derivedFrom))"
        }.joined(separator: "\n")
    }

    private func classifyToken(_ content: String) -> AgenticStreamToken.TokenType {
        let lowered = content.lowercased()
        if lowered.contains("tool:") || lowered.contains("execute:") || lowered.contains("action:") {
            return .toolCall
        }
        if lowered.contains("reason:") || lowered.contains("thinking:") || lowered.contains("analysis:") {
            return .reasoning
        }
        if lowered.contains("error:") || lowered.contains("failed:") {
            return .error
        }
        if lowered.contains("result:") || lowered.contains("output:") {
            return .toolResult
        }
        return .text
    }

    // MARK: - Errors

    enum SessionError: Error, LocalizedError {
        case frameworkUnavailable
        case platformUnsupported
        case sessionInitFailed(String)
        case streamFailed(String)

        var errorDescription: String? {
            switch self {
            case .frameworkUnavailable:
                return "FoundationModels framework is not available on this device."
            case .platformUnsupported:
                return "This platform version does not support Foundation Models. iOS 17.0+ or macOS 14.0+ required."
            case .sessionInitFailed(let reason):
                return "Failed to initialize language model session: \(reason)"
            case .streamFailed(let reason):
                return "Streaming failed: \(reason)"
            }
        }
    }
}
