import Foundation

public final class AgentLongTermMemory {
    private let store: AgentMemoryStore

    public init(store: AgentMemoryStore = AgentMemoryStore()) {
        self.store = store
    }

    public func persist(_ entry: AgentMemoryEntry) {
        store.add(entry)
    }

    public func retrieve(query: String) -> [AgentMemoryEntry] {
        store.search(query: query)
    }
}
