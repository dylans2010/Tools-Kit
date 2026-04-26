import Foundation

public struct AgentDebugExporter {
    public init() {}

    public func export(session: AgentDebugSession) throws -> Data {
        try JSONEncoder().encode(session.getSnapshots())
    }
}
