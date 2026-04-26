import Foundation

struct AgentAutomationValidator {
    func validate(steps: [AgentAutomationStep]) -> [String] {
        if steps.isEmpty { return ["At least one automation step is required"] }
        return steps.enumerated().compactMap { index, step in
            step.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Step \(index + 1) has an empty name" : nil
        }
    }
}
