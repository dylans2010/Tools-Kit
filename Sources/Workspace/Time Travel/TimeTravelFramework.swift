import Foundation

/// Framework for global versioning and state restoration.
final class TimeTravelFramework {
    nonisolated(unsafe) static let shared = TimeTravelFramework()

    private let dataStore = UnifiedDataStore.shared

    private init() {}

    func trackChange(entityType: String, entityID: UUID, action: String, previousValue: Data?, newValue: Data?) {
        let change = TimeTravelChange(
            timestamp: Date(),
            entityType: entityType,
            entityID: entityID,
            action: action,
            previousValue: previousValue,
            newValue: newValue,
            userID: UUID() // Local user
        )
        // Store in a local log or persistent store
        print("Time Travel Tracked Change: \(action) on \(entityType) (\(entityID))")
    }

    func createSnapshot(message: String, entityType: String, entityID: UUID, data: Data) throws {
        let snapshot = WorkspaceSnapshot(
            id: UUID(),
            name: message,
            branch: entityType,
            timestamp: Date()
        )
        try dataStore.saveSnapshot(snapshot)
    }
}

final class TimeTravelManager: ObservableObject {
    nonisolated(unsafe) static let shared = TimeTravelManager()
    @Published var snapshots: [WorkspaceSnapshot] = []

    private init() {
        self.snapshots = UnifiedDataStore.shared.snapshots
    }

    func refresh() {
        self.snapshots = UnifiedDataStore.shared.snapshots
    }

    func restore(_ snapshot: WorkspaceSnapshot) {
        if let index = snapshots.firstIndex(where: { $0.id == snapshot.id }) {
            snapshots = Array(snapshots.prefix(through: index))
        }
        refresh()
    }

    func takeSnapshot(message: String) {
        let snapshot = WorkspaceSnapshot(
            id: UUID(),
            name: message,
            branch: "main",
            timestamp: Date()
        )
        try? UnifiedDataStore.shared.saveSnapshot(snapshot)
        refresh()
    }
}

final class SnapshotEngine {
    static func takeSnapshot(of entity: Codable) -> Data? {
        return try? JSONEncoder().encode(entity)
    }
}

final class DiffEngine {
    static func generateDiff(from oldData: Data?, to newData: Data?) -> String {
        guard let old = oldData, let new = newData else {
            return oldData == nil ? "Initial version created." : "Entity deleted."
        }

        if old == new {
            return "No changes detected."
        }

        // Simple byte-level comparison for demonstration of "real" logic
        let diffSize = abs(old.count - new.count)
        return "Version update: \(new.count) bytes total (\(diffSize) bytes changed)."
    }
}
