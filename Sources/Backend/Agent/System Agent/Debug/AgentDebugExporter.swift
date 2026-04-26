import Foundation

struct AgentDebugExporter {
    init() {}

    func export(session: AgentDebugSession) throws -> Data {
        try JSONEncoder().encode(session.getSnapshots())
    }
}
