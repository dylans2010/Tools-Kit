import Foundation

public final class AgentDemoResultRecorder {
    public private(set) var results: [UUID: String] = [:]

    public init() {}

    public func record(scriptId: UUID, result: String) {
        results[scriptId] = result
    }
}
