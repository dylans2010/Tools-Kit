import Foundation

public final class AgentToolQueue {
    private var queue: [AgentToolCall] = []
    private let lock = NSLock()

    public init() {}

    public func enqueue(_ toolCall: AgentToolCall) {
        lock.lock()
        defer { lock.unlock() }
        queue.append(toolCall)
    }

    public func dequeue() -> AgentToolCall? {
        lock.lock()
        defer { lock.unlock() }
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }
}
