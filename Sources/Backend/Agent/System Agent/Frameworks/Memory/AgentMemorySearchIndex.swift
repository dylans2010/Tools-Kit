import Foundation

final class AgentMemorySearchIndex {
    private var index: [String: Set<UUID>] = [:]
    private let lock = NSLock()

    init() {}

    func index(entry: AgentMemoryEntry) {
        lock.lock()
        defer { lock.unlock() }
        let words = entry.content.lowercased().components(separatedBy: .punctuationCharacters).joined().components(separatedBy: .whitespaces)
        for word in words where !word.isEmpty {
            index[word, default: []].insert(entry.id)
        }
    }

    func search(term: String) -> Set<UUID> {
        lock.lock()
        defer { lock.unlock() }
        return index[term.lowercased()] ?? []
    }
}
