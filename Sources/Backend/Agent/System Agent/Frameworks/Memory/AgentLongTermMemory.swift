import Foundation

final class AgentLongTermMemory {
    private let store: AgentMemoryStore

    init(store: AgentMemoryStore = AgentMemoryStore()) {
        self.store = store
    }

    func persist(_ entry: AgentMemoryEntry) {
        store.add(entry)
    }

    func retrieve(query: String) -> [AgentMemoryEntry] {
        store.search(query: query)
    }
}
