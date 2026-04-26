import Foundation

final class AgentAutomationEngine {
    private let agent: SystemAgent

    init(agent: SystemAgent) {
        self.agent = agent
    }

    func execute(script: AgentAutomationScript) async -> AgentAutomationResult {
        AgentAPILogger.shared.log(.info, "Executing automation script: \(script.name)")

        var output = "Execution started for script: \(script.name)\n"

        for step in script.steps {
            output += "Executing step: \(step.action)\n"
            do {
                // Map automation step to agent message
                let response = try await agent.sendMessage("Execute automation step: \(step.action) with parameters: \(step.parameters)")
                output += "Step output: \(response.content)\n"
            } catch {
                return AgentAutomationResult(scriptId: script.id, success: false, output: output, error: "Step \(step.action) failed: \(error.localizedDescription)")
            }
        }

        output += "Execution completed successfully."

        return AgentAutomationResult(scriptId: script.id, success: true, output: output, error: nil)
    }
}
