import Foundation

struct Workflow: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var trigger: WorkflowTrigger
    var steps: [WorkflowStep]
    var isEnabled: Bool
    var lastRunAt: Date?
}

struct WorkflowTrigger: Codable {
    let type: String // e.g., "event", "time", "manual"
    let actionType: String? // for event triggers (e.g., "note.created")
}

struct WorkflowStep: Identifiable, Codable {
    let id: UUID
    var actionType: String // e.g., "ai.summarize", "mail.send", "note.update"
    var config: [String: String]
}

struct WorkflowRun: Identifiable, Codable {
    let id: UUID
    let workflowID: UUID
    let timestamp: Date
    let status: RunStatus
    let logs: [String]

    enum RunStatus: String, Codable {
        case success, failure, running
    }
}
