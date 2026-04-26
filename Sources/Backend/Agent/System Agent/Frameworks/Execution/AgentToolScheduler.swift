import Foundation

public final class AgentToolScheduler {
    private let queue = AgentToolQueue()

    public init() {}

    public func schedule(toolCall: AgentToolCall, after delay: TimeInterval) {
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.queue.enqueue(toolCall)
            AgentAPILogger.shared.log(.info, "Scheduled tool call enqueued: \(toolCall.name)")
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
