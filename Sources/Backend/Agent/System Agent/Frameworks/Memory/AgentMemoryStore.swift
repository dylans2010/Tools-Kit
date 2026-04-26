import Foundation

final class AgentMemoryStore {
    private var entries: [AgentMemoryEntry] = []
    private let lock = NSLock()

    init() {}

    func add(_ entry: AgentMemoryEntry) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(entry)
    }

    func allEntries() -> [AgentMemoryEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    func search(query: String) -> [AgentMemoryEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }
}
