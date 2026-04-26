import Foundation

final class AgentAutomationScheduler {
    private let agent: SystemAgent

    init(agent: SystemAgent) {
        self.agent = agent
    }

    func schedule(script: AgentAutomationScript, at date: Date) {
        let delay = date.timeIntervalSinceNow
        guard delay > 0 else { return }

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            Task {
                let engine = AgentAutomationEngine(agent: self.agent)
                _ = await engine.execute(script: script)
            }
        }
    }
}
