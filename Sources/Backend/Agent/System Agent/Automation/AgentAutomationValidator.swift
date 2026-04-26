import Foundation

public struct AgentAutomationValidator {
    public init() {}

    public func validate(script: AgentAutomationScript) -> Bool {
        !script.name.isEmpty && !script.steps.isEmpty
    }
}
