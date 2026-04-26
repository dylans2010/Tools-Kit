import Foundation

struct AgentTaskDependencyResolver {
    func resolve(steps: [AgentAutomationStep]) -> [AgentAutomationStep] { steps.sorted { $0.index < $1.index } }
}
