import Foundation

final class AgentToolResultCache {
    private var cache: [String: AgentToolResult] = [:]
    private let lock = NSLock()

    init() {}

    func set(_ result: AgentToolResult, for id: String) {
        lock.lock()
        defer { lock.unlock() }
        cache[id] = result
    }

    func get(for id: String) -> AgentToolResult? {
        lock.lock()
        defer { lock.unlock() }
        return cache[id]
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}
