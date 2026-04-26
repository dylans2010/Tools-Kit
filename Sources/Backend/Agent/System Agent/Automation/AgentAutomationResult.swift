import Foundation

struct AgentAutomationResult: Identifiable, Codable {
    let id: UUID
    let scriptID: UUID
    let startedAt: Date
    let completedAt: Date
    let duration: TimeInterval
    let stepResults: [UUID: StepResult]
    let totalToolCallsExecuted: Int
    let totalCodeBlocksGenerated: Int
    let totalTokensUsed: Int
    let warnings: [AgentWarning]
    let overallStatus: OverallStatus

    enum OverallStatus: String, Codable { case success, partialSuccess, failed, timedOut }

    struct StepResult: Codable {
        let stepID: UUID
        let output: String
        let toolsUsed: [String]
        let duration: TimeInterval
        let status: AgentAutomationStep.StepStatus
        let error: String?
    }
}
