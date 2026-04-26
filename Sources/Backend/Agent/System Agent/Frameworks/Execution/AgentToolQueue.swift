import Foundation

final class AgentToolQueue {
    private var queue: [AgentToolCall] = []
    private let lock = NSLock()

    init() {}

    func enqueue(_ toolCall: AgentToolCall) {
        lock.lock()
        defer { lock.unlock() }
        queue.append(toolCall)
    }

    func dequeue() -> AgentToolCall? {
        lock.lock()
        defer { lock.unlock() }
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }
}
