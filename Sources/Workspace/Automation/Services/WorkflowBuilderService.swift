import Foundation

class WorkflowBuilderService {
    static let shared = WorkflowBuilderService()

    private init() {}

    func buildFromNaturalLanguage(_ text: String) -> Workflow? {
        // Mock NL parsing
        if text.contains("task") && text.contains("note") {
            return Workflow(id: UUID(), name: "Auto Task Note", steps: [
                WorkflowStep(id: UUID(), actionType: "On New Task", parameters: [:]),
                WorkflowStep(id: UUID(), actionType: "Create Note", parameters: [:])
            ])
        }
        return nil
    }
}
