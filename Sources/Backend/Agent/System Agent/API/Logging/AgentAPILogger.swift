import Foundation

public final class AgentAPILogger {
    public static let shared = AgentAPILogger()
    private var entries: [AgentLogEntry] = []
    private let queue = DispatchQueue(label: "com.tools-kit.agent.logging")

    private init() {}

    public func log(_ level: AgentLogLevel, _ message: String, metadata: [String: String] = [:]) {
        let entry = AgentLogEntry(level: level, message: message, metadata: metadata)
        queue.async {
            self.entries.append(entry)
            print("[\(level.rawValue.uppercased())] \(message)")
        }
    }

    public func getLogs() -> [AgentLogEntry] {
        queue.sync { entries }
    }
}
