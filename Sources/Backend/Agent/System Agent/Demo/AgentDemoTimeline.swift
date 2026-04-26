import Foundation

public final class AgentDemoTimeline {
    public private(set) var events: [String] = []

    public init() {}

    public func addEvent(_ event: String) {
        events.append("\(Date()): \(event)")
    }
}
