import Foundation

actor AgentMemoryStore {
    static let shared = AgentMemoryStore()

    private var shortTerm: [AgentMemoryEntry] = []
    private var longTerm: [AgentMemoryEntry] = []
    private let index = AgentMemorySearchIndex()

    func store(entry: AgentMemoryEntry) {
        shortTerm.append(entry)
        if shortTerm.count > 50 { shortTerm.removeFirst(shortTerm.count - 50) }
        longTerm.append(entry)
        index.index(entry: entry)
    }

    func recall(query: String, limit: Int) async -> [AgentMemoryEntry] { index.search(query: query, limit: limit) }
    func purgeShortTerm() { shortTerm.removeAll() }
    func snapshot() -> AgentContextSnapshot { AgentContextSnapshot(memoryEntries: longTerm) }
    func shortTermEntries() -> [AgentMemoryEntry] { shortTerm }
    func longTermCount() -> Int { longTerm.count }
}
