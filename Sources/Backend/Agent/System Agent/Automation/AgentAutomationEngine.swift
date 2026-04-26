import Foundation

struct AgentAutomationProgress {
    let stepIndex: Int
    let totalSteps: Int
    let activeToolName: String?
    let elapsedTime: TimeInterval
    let completionPercentage: Double
}

actor AgentAutomationEngine {
    private let agent: SystemAgent
    private let configuration: AgentConfiguration
    private let dependencyResolver = AgentTaskDependencyResolver()
    private var progressContinuation: AsyncStream<AgentAutomationProgress>.Continuation?

    init(agent: SystemAgent, configuration: AgentConfiguration = .default) {
        self.agent = agent
        self.configuration = configuration
    }

    nonisolated func progressStream() -> AsyncStream<AgentAutomationProgress> {
        AsyncStream { continuation in
            Task { await self.setProgressContinuation(continuation) }
        }
    }

    private func setProgressContinuation(_ continuation: AsyncStream<AgentAutomationProgress>.Continuation) {
        self.progressContinuation = continuation
    }

    func run(script: AgentAutomationScript, context: AgentContext) async throws -> AgentAutomationResult {
        let startedAt = Date()
        var results: [UUID: AgentAutomationResult.StepResult] = [:]
        let ordered = dependencyResolver.resolve(steps: script.steps)
        for (idx, step) in ordered.enumerated() {
            let stepStart = Date()
            do {
                let output = try await agent.sendMessage(step.prompt).content
                results[step.id] = .init(stepID: step.id, output: output, toolsUsed: step.expectedTools, duration: Date().timeIntervalSince(stepStart), status: .completed, error: nil)
            } catch {
                results[step.id] = .init(stepID: step.id, output: "", toolsUsed: step.expectedTools, duration: Date().timeIntervalSince(stepStart), status: .failed, error: error.localizedDescription)
                if !step.continueOnFailure { throw error }
            }
            progressContinuation?.yield(.init(stepIndex: idx + 1, totalSteps: ordered.count, activeToolName: step.expectedTools.first, elapsedTime: Date().timeIntervalSince(startedAt), completionPercentage: Double(idx + 1) / Double(max(ordered.count, 1))))
        }
        return AgentAutomationResult(id: UUID(), scriptID: script.id, startedAt: startedAt, completedAt: Date(), duration: Date().timeIntervalSince(startedAt), stepResults: results, totalToolCallsExecuted: 0, totalCodeBlocksGenerated: 0, totalTokensUsed: 0, warnings: [], overallStatus: .success)
    }
}
