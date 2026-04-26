import Foundation

actor AgentAPILogger {
    static let shared = AgentAPILogger()
    private var logs: [AgentLogEntry] = []

    func log(level: AgentLogLevel, component: String, message: String) {
        logs.append(AgentLogEntry(id: UUID(), timestamp: Date(), level: level, component: component, message: message))
    }

    func allLogs() -> [AgentLogEntry] { logs }
    func clearLogs() { logs.removeAll() }
}
