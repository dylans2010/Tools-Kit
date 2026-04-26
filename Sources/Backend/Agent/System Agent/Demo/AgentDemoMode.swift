import Foundation

actor AgentDemoMode {
    static let shared = AgentDemoMode()

    enum DemoStatus {
        case idle, preparing
        case running(script: AgentDemoScript, currentStep: Int, elapsed: TimeInterval)
        case paused(at: Int)
        case completed(result: AgentDemoResultRecorder.Recording)
        case failed(step: Int, error: Error)
    }

    private(set) var status: DemoStatus = .idle
    private var currentScript: AgentDemoScript?
    private var currentStepIndex = 0

    func start(script: AgentDemoScript) async throws { status = .preparing; currentScript = script; currentStepIndex = 0; status = .running(script: script, currentStep: 0, elapsed: 0) }
    func pause() { status = .paused(at: currentStepIndex) }
    func resume() async throws { if let script = currentScript { status = .running(script: script, currentStep: currentStepIndex, elapsed: 0) } }
    func stop() { status = .idle; currentScript = nil }
    func exportRecording() -> AgentDemoResultRecorder.Recording? { nil }
}
