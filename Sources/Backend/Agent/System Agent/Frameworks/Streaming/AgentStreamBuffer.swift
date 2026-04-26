import Foundation

final class AgentStreamBuffer {
    private var buffer: String = ""
    private let lock = NSLock()

    init() {}

    func append(_ content: String) {
        lock.lock()
        defer { lock.unlock() }
        buffer += content
    }

    func flush() -> String {
        lock.lock()
        defer { lock.unlock() }
        let current = buffer
        buffer = ""
        return current
    }
}
