import Foundation

public final class AgentAutomationScheduler {
    public init() {}

    public func schedule(script: AgentAutomationScript, at date: Date) {
        let delay = date.timeIntervalSinceNow
        guard delay > 0 else { return }

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            Task {
                let engine = AgentAutomationEngine()
                _ = await engine.execute(script: script)
            }
        }
    }
}
