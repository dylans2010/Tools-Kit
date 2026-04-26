import Foundation

final class AgentShortTermMemory {
    private var entries: [AgentMemoryEntry] = []
    let capacity: Int

    init(capacity: Int = 100) {
        self.capacity = capacity
    }

    func add(_ content: String) {
        if entries.count >= capacity {
            entries.removeFirst()
        }
        entries.append(AgentMemoryEntry(content: content, tags: ["short-term"]))
    }

    var recentEntries: [AgentMemoryEntry] {
        entries
    }
}
