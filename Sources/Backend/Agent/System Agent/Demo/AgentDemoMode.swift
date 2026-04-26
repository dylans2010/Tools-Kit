import Foundation

public final class AgentDemoMode {
    public private(set) var isRunning: Bool = false

    public init() {}

    public func startDemo(script: AgentDemoScript, onStep: (AgentDemoStep) -> Void) async {
        isRunning = true
        for step in script.steps {
            guard isRunning else { break }
            onStep(step)
            try? await Task.sleep(nanoseconds: UInt64(step.delay * 1_000_000_000))
        }
        isRunning = false
    }

    public func stopDemo() {
        isRunning = false
    }
}
