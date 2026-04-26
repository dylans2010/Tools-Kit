import Foundation

struct AgentDemoTimeline: Identifiable {
    let id = UUID()
    let script: AgentDemoScript
    var events: [DemoTimelineEvent]
    var startedAt: Date?
    var elapsedSeconds: TimeInterval
    var currentStepIndex: Int
    var progressPercentage: Double
}

struct DemoTimelineEvent: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let stepIndex: Int
    let type: EventType
    let description: String
    let toolName: String?
    let codeGenerated: Bool

    enum EventType: String, Codable {
        case stepStarted, toolCalled, toolCompleted, codeGenerated, stepCompleted, stepFailed, warning, agentThinking
    }
}
