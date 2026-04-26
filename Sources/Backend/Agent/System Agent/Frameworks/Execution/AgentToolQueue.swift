import Foundation

struct AgentToolQueue {
    private var queue: [String] = []

    mutating func enqueue(_ tool: String) { queue.append(tool) }
    mutating func dequeue() -> String? { queue.isEmpty ? nil : queue.removeFirst() }
    var isEmpty: Bool { queue.isEmpty }
}
