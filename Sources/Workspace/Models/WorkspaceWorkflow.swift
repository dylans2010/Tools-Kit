import Foundation

struct WorkspaceWorkflow: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var icon: String
    var trigger: WorkflowTrigger
    var actions: [WorkflowAction]
    var isEnabled: Bool
    var createdAt: Date

    struct WorkflowTrigger: Codable {
        var capability: String
        var action: String
    }

    struct WorkflowAction: Codable, Identifiable {
        let id: UUID
        var type: String
        var parameters: [String: String]
    }
}
