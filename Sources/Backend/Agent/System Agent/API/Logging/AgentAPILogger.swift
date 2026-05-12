import Foundation

final class AgentAPILogger {
    nonisolated(unsafe) static let shared = AgentAPILogger()
    private var entries: [AgentLogEntry] = []
    private let queue = DispatchQueue(label: "com.tools-kit.agent.logging")

    private init() {}

    func log(_ level: AgentLogLevel, _ message: String, metadata: [String: String] = [:]) {
        let entry = AgentLogEntry(level: level, message: message, metadata: metadata)
        queue.async {
            self.entries.append(entry)
            print("[\(level.rawValue.uppercased())] \(message)")
        }
    }

    func getLogs() -> [AgentLogEntry] {
        queue.sync { entries }
    }
}
