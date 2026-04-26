import Foundation

struct AgentLogExporter {
    init() {}

    func export(logs: [AgentLogEntry]) throws -> Data {
        try JSONEncoder().encode(logs)
    }
}
