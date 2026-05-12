import Foundation

struct AgentDebugExporter: Sendable {
    init() {}

    func export(session: AgentDebugSession) throws -> Data {
        try JSONEncoder().encode(session.getSnapshots())
    }
}
