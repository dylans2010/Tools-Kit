import Foundation

final class AgentMemorySearchIndex {
    private var entries: [UUID: AgentMemoryEntry] = [:]
    private var index: [String: Set<UUID>] = [:]

    func index(entry: AgentMemoryEntry) {
        entries[entry.id] = entry
        tokenize(entry.content + " " + entry.tags.joined(separator: " ")).forEach { token in
            index[token, default: []].insert(entry.id)
        }
    }

    func search(query: String, limit: Int) -> [AgentMemoryEntry] {
        var scores: [UUID: Int] = [:]
        for token in tokenize(query) {
            for id in index[token, default: []] { scores[id, default: 0] += 1 }
        }
        return scores.sorted { $0.value > $1.value }.prefix(limit).compactMap { entries[$0.key] }
    }

    private func tokenize(_ text: String) -> [String] {
        text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
    }
}
