import Foundation
import FoundationModels
import Combine

@MainActor
final class AgenticCoreSessionManager: ObservableObject {
    static let shared = AgenticCoreSessionManager()

    @Published var streamedTokens: [AgenticStreamToken] = []
    @Published var currentResponse: String = ""
    @Published var isStreaming: Bool = false
    @Published var executionState: AgenticExecutionState = .idle

    private var session: LanguageModelSession?
    private var activeTask: Task<Void, Never>?

    private let traceStore = AgenticExecutionTraceStore.shared

    private init() {}

    // MARK: - Session Lifecycle

    func createSession(instructions: String) {
        session = LanguageModelSession(instructions: instructions)
        traceStore.record(phase: "session", detail: "Created new LanguageModelSession")
    }

    func resetSession() {
        activeTask?.cancel()
        activeTask = nil
        session = nil
        streamedTokens.removeAll()
        currentResponse = ""
        isStreaming = false
        executionState = .idle
        traceStore.record(phase: "session", detail: "Session reset")
    }

    // MARK: - Streaming Generation

    func streamResponse(prompt: String) async throws -> AgenticModelResponse {
        guard let session else {
            throw AgenticSessionError.noActiveSession
        }

        executionState = .streaming
        isStreaming = true
        currentResponse = ""
        streamedTokens.removeAll()

        traceStore.record(phase: "streaming", detail: "Starting streaming for prompt: \(prompt.prefix(100))...")

        let startTime = Date()

        let stream = session.streamResponse(
            to: prompt,
            generating: AgenticModelResponse.self
        )

        var partialText = ""

        for try await partial in stream {
            if Task.isCancelled {
                executionState = .interrupted
                isStreaming = false
                traceStore.record(phase: "streaming", detail: "Stream interrupted by cancellation")
                throw AgenticSessionError.interrupted
            }

            let newContent = partial.message
            if newContent.count > partialText.count {
                let delta = String(newContent.dropFirst(partialText.count))
                let token = AgenticStreamToken(content: delta, isReasoning: false)
                streamedTokens.append(token)
                partialText = newContent
                currentResponse = partialText
            }
        }

        let result = try await stream.result
        let elapsed = Date().timeIntervalSince(startTime) * 1000

        isStreaming = false
        executionState = .completed
        currentResponse = result.message

        traceStore.record(
            phase: "streaming",
            detail: "Streaming complete: \(result.actions.count) actions, isComplete=\(result.isComplete)",
            durationMs: elapsed
        )

        return result
    }

    // MARK: - Continuation Streaming

    func streamContinuation(followUp: String) async throws -> AgenticModelResponse {
        guard session != nil else {
            throw AgenticSessionError.noActiveSession
        }

        executionState = .streaming
        isStreaming = true

        traceStore.record(phase: "continuation", detail: "Streaming continuation: \(followUp.prefix(80))...")

        let response = try await streamResponse(prompt: followUp)
        return response
    }

    // MARK: - Interruption

    func interrupt() {
        activeTask?.cancel()
        activeTask = nil
        isStreaming = false
        executionState = .interrupted
        traceStore.record(phase: "interruption", detail: "User-initiated stream interruption")
    }
}

// MARK: - Errors

enum AgenticSessionError: LocalizedError {
    case noActiveSession
    case interrupted
    case deviceNotSupported(String)

    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active Foundation Models session. Call createSession first."
        case .interrupted:
            return "Streaming was interrupted."
        case .deviceNotSupported(let reason):
            return "Device not supported: \(reason)"
        }
    }
}
