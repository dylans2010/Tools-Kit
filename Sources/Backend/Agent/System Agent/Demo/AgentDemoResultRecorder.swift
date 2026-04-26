import Foundation

actor AgentDemoResultRecorder {
    struct Recording: Identifiable, Codable {
        let id: UUID
        let scriptName: String
        let duration: TimeInterval
        let completedAt: Date
        let timeline: [DemoTimelineEvent]
        let allMessages: [SystemAgentMessage]
        let allToolResults: [AgentToolResult]
        let generatedCodeBlocks: [String]
        let telemetrySummary: AgentTelemetrySummary
        let overallStatus: AgentAutomationResult.OverallStatus
    }

    private var scriptName = ""
    private var startedAt = Date()
    private var timeline: [DemoTimelineEvent] = []
    private var messages: [SystemAgentMessage] = []
    private var tools: [AgentToolResult] = []
    private var codeBlocks: [String] = []

    func startRecording(for script: AgentDemoScript) { scriptName = script.name; startedAt = Date() }
    func record(event: DemoTimelineEvent) { timeline.append(event) }
    func record(message: SystemAgentMessage) { messages.append(message) }
    func record(toolResult: AgentToolResult) { tools.append(toolResult) }
    func record(codeBlock: String) { codeBlocks.append(codeBlock) }
    func finalize() async -> Recording {
        Recording(id: UUID(), scriptName: scriptName, duration: Date().timeIntervalSince(startedAt), completedAt: Date(), timeline: timeline, allMessages: messages, allToolResults: tools, generatedCodeBlocks: codeBlocks, telemetrySummary: await AgentTelemetry.shared.sessionSummary(), overallStatus: .success)
    }
}
