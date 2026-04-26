import Foundation

struct AgentAutomationStep: Identifiable, Codable {
    let id: UUID
    let index: Int
    let name: String
    let prompt: String
    let expectedTools: [String]
    let dependsOn: [UUID]
    let continueOnFailure: Bool
    let timeoutOverride: TimeInterval?
    var status: StepStatus
    var result: AgentAutomationResult?

    enum StepStatus: String, Codable { case pending, running, completed, failed, skipped }
}
