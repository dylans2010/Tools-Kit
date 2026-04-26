import Foundation

actor AgentTelemetry {
    static let shared = AgentTelemetry()

    struct ToolRecord { let name: String; let duration: TimeInterval; let success: Bool }
    private var apiCalls: [(TimeInterval, Int, String)] = []
    private var toolCalls: [ToolRecord] = []
    private var codeBlocks: [(String, Int)] = []
    private var errors: [AgentAPIError] = []
    private var warnings: [AgentWarning] = []

    func recordAPICall(latency: TimeInterval, tokenCount: Int, model: String) { apiCalls.append((latency, tokenCount, model)) }
    func recordToolExecution(name: String, duration: TimeInterval, success: Bool) { toolCalls.append(.init(name: name, duration: duration, success: success)) }
    func recordCodeBlock(language: String, lineCount: Int) { codeBlocks.append((language, lineCount)) }
    func recordError(_ error: AgentAPIError) { errors.append(error) }
    func recordWarning(_ warning: AgentWarning) { warnings.append(warning) }
    func sessionSummary() -> AgentTelemetrySummary { makeSummary() }
    func allTimeSummary() -> AgentTelemetrySummary { makeSummary() }
    func reset() { apiCalls.removeAll(); toolCalls.removeAll(); codeBlocks.removeAll(); errors.removeAll(); warnings.removeAll() }

    private func makeSummary() -> AgentTelemetrySummary {
        let totalAPICalls = apiCalls.count
        let avgLatency = totalAPICalls == 0 ? 0 : apiCalls.map { $0.0 }.reduce(0, +) / Double(totalAPICalls)
        let tokens = apiCalls.map { $0.1 }.reduce(0, +)
        let totalTools = toolCalls.count
        let successes = toolCalls.filter(\.success).count
        return AgentTelemetrySummary(totalAPICalls: totalAPICalls, averageLatency: avgLatency, totalTokensUsed: tokens, totalToolExecutions: totalTools, toolSuccessRate: totalTools == 0 ? 1 : Double(successes) / Double(totalTools), totalCodeBlocksGenerated: codeBlocks.count, errorCount: errors.count, warningCount: warnings.count, mostUsedTools: Dictionary(toolCalls.map { ($0.name, 1) }, uniquingKeysWith: +), averageIterationsPerSession: 0)
    }
}

struct AgentTelemetrySummary: Codable {
    let totalAPICalls: Int
    let averageLatency: TimeInterval
    let totalTokensUsed: Int
    let totalToolExecutions: Int
    let toolSuccessRate: Double
    let totalCodeBlocksGenerated: Int
    let errorCount: Int
    let warningCount: Int
    let mostUsedTools: [String: Int]
    let averageIterationsPerSession: Double
}
