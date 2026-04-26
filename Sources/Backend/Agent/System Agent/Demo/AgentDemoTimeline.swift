import Foundation

final class AgentDemoTimeline {
    private(set) var events: [String] = []

    init() {}

    func addEvent(_ event: String) {
        events.append("\(Date()): \(event)")
    }
}
