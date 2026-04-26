import Foundation

public final class AgentMemoryStore {
    private var entries: [AgentMemoryEntry] = []
    private let lock = NSLock()

    public init() {}

    public func add(_ entry: AgentMemoryEntry) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(entry)
    }

    public func allEntries() -> [AgentMemoryEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    public func search(query: String) -> [AgentMemoryEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }
}
