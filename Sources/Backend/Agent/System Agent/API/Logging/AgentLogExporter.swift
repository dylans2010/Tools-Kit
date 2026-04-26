import Foundation

public struct AgentLogExporter {
    public init() {}

    public func export(logs: [AgentLogEntry]) throws -> Data {
        try JSONEncoder().encode(logs)
    }
}
