import Foundation

struct EditSnapshot: Identifiable {
    let id: UUID
    let projectID: UUID
    let label: String
    let timestamp: Date
}

final class NonDestructivePipelineService {
    static let shared = NonDestructivePipelineService()
    private(set) var snapshots: [EditSnapshot] = []

    func capture(projectID: UUID, label: String) {
        snapshots.insert(EditSnapshot(id: UUID(), projectID: projectID, label: label, timestamp: Date()), at: 0)
        EditingFramework.shared.record(projectID: projectID, name: "snapshot", metadata: ["label": label])
    }
}
