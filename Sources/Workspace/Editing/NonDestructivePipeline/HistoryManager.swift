import Foundation

/// Represents a state snapshot in the editing history.
struct EditSnapshot: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let layerData: [EditingLayer]
    let message: String
}

/// Core manager for the non-destructive editing pipeline.
final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published var history: [UUID: [EditSnapshot]] = [:] // ProjectID: Snapshots

    private init() {}

    func saveSnapshot(projectID: UUID, layers: [EditingLayer], message: String) {
        let snapshot = EditSnapshot(id: UUID(), timestamp: Date(), layerData: layers, message: message)
        var current = history[projectID] ?? []
        current.insert(snapshot, at: 0)
        history[projectID] = current
    }

    func revertToSnapshot(projectID: UUID, snapshotID: UUID) -> [EditingLayer]? {
        return history[projectID]?.first(where: { $0.id == snapshotID })?.layerData
    }
}
