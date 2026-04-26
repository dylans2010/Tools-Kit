import Foundation

struct AgentAutomationValidator {
    init() {}

    func validate(script: AgentAutomationScript) -> Bool {
        !script.name.isEmpty && !script.steps.isEmpty
    }
}
