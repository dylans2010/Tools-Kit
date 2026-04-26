import Foundation

public final class AgentStreamBuffer {
    private var buffer: String = ""
    private let lock = NSLock()

    public init() {}

    public func append(_ content: String) {
        lock.lock()
        defer { lock.unlock() }
        buffer += content
    }

    public func flush() -> String {
        lock.lock()
        defer { lock.unlock() }
        let current = buffer
        buffer = ""
        return current
    }
}
