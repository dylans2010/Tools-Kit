import Foundation

struct AgentLogExporter: Sendable {
    init() {}

    func export(logs: [AgentLogEntry]) throws -> Data {
        try JSONEncoder().encode(logs)
    }
}
