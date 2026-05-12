import Foundation

struct AgentAutomationValidator: Sendable {
    init() {}

    func validate(script: AgentAutomationScript) -> Bool {
        !script.name.isEmpty && !script.steps.isEmpty
    }
}
