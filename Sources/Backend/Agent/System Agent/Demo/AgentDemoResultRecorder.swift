import Foundation

final class AgentDemoResultRecorder {
    private(set) var results: [UUID: String] = [:]

    init() {}

    func record(scriptId: UUID, result: String) {
        results[scriptId] = result
    }
}
