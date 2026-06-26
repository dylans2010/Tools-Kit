import Foundation
import Observation

@MainActor @Observable
final class OpenClawMessageBus {
    static let shared = OpenClawMessageBus()

    private var continuations: [UUID: AsyncStream<OpenClawEvent>.Continuation] = [:]

    func events() -> AsyncStream<OpenClawEvent> {
        AsyncStream { continuation in
            let id = UUID()
            self.continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    @MainActor
    func publish(_ event: OpenClawEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }
}
