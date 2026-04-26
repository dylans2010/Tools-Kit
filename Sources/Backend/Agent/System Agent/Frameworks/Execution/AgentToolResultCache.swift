import Foundation

public final class AgentToolResultCache {
    private var cache: [String: AgentToolResult] = [:]
    private let lock = NSLock()

    public init() {}

    public func set(_ result: AgentToolResult, for id: String) {
        lock.lock()
        defer { lock.unlock() }
        cache[id] = result
    }

    public func get(for id: String) -> AgentToolResult? {
        lock.lock()
        defer { lock.unlock() }
        return cache[id]
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}
