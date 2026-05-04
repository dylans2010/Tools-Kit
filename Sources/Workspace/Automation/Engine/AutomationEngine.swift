import Foundation

class AutomationEngine: ObservableObject {
    static let shared = AutomationEngine()

    @Published var workflows: [Workflow] = []

    private init() {}

    func execute(workflow: Workflow) async {
        print("Executing workflow: \(workflow.name)")
        for step in workflow.steps {
            try? await Task.sleep(nanoseconds: 500_000_000)
            print("Step \(step.id) complete")
        }
    }
}

struct Workflow: Identifiable, Codable {
    let id: UUID
    var name: String
    var steps: [WorkflowStep]
}

struct WorkflowStep: Identifiable, Codable {
    let id: UUID
    var actionType: String
    var parameters: [String: String]
}
