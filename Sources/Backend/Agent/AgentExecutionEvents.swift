import Foundation

enum AgentExecutionEventType: String, Codable, CaseIterable {
    case sessionStarted = "session_started"
    case stepStarted = "step_started"
    case stepProgress = "step_progress"
    case logOutput = "log_output"
    case fileGenerated = "file_generated"
    case fileUpdated = "file_updated"
    case gitOperation = "git_operation"
    case workflowTriggered = "workflow_triggered"
    case sessionCompleted = "session_completed"
    case sessionFailed = "session_failed"
}

struct AgentExecutionEvent: Identifiable, Codable {
    let id: String
    let sessionId: String
    let timestamp: Date
    let type: AgentExecutionEventType
    let stepId: String?
    let title: String
    let message: String
    let payload: [String: AnyCodable]

    init(
        id: String = UUID().uuidString,
        sessionId: String,
        timestamp: Date = Date(),
        type: AgentExecutionEventType,
        stepId: String? = nil,
        title: String,
        message: String,
        payload: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.type = type
        self.stepId = stepId
        self.title = title
        self.message = message
        self.payload = payload
    }
}

struct AgentFileOperation: Identifiable, Codable {
    enum OperationType: String, Codable {
        case generated
        case updated
    }

    let id: String
    let path: String
    let operation: OperationType
    let patch: String?
    let content: String?
    let timestamp: Date
}

struct AgentGitOperation: Identifiable, Codable {
    let id: String
    let action: String
    let status: String
    let summary: String
    let timestamp: Date
}

struct AgentWorkflowTrigger: Identifiable, Codable {
    let id: String
    let workflowName: String
    let status: String
    let details: String
    let timestamp: Date
}

struct AgentDebugSnapshot: Codable {
    let rawSession: AgentSession?
    let rawActivities: [AgentActivity]
    let convertedEvents: [AgentExecutionEvent]
    let stateTransition: String
    let uiTrigger: String
    let frameworkPhase: String
}
