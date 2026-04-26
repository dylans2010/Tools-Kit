import Foundation

public final class AgentShortTermMemory {
    private var entries: [AgentMemoryEntry] = []
    public let capacity: Int

    public init(capacity: Int = 100) {
        self.capacity = capacity
    }

    public func add(_ content: String) {
        if entries.count >= capacity {
            entries.removeFirst()
        }
        entries.append(AgentMemoryEntry(content: content, tags: ["short-term"]))
    }

    public var recentEntries: [AgentMemoryEntry] {
        entries
    }
}
