import Foundation
import Combine

/// Saves, restores, and compares full workspace snapshots.
final class WorkspaceSnapshotService: ObservableObject {
    static let shared = WorkspaceSnapshotService()

    struct Snapshot: Codable, Identifiable {
        let id: UUID
        var label: String
        let createdAt: Date
        let spacesData: Data   // JSON-encoded [CollaborationSpace]
        let tasksData: Data    // JSON-encoded [ProjectExecutionBoardTool.BoardTask]
        let decisionsData: Data
        var notes: String
    }

    struct SnapshotDiff: Identifiable {
        let id = UUID()
        let field: String
        let before: String
        let after: String
    }

    @Published private(set) var snapshots: [Snapshot] = []

    private let storageFile = "workspace_snapshots.json"

    private init() {
        loadData()
    }

    // MARK: - Save

    func saveSnapshot(label: String, notes: String = "") {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let spacesData = (try? encoder.encode(CollaborationManager.shared.spaces)) ?? Data()
        let tasksData = (try? encoder.encode(ProjectExecutionBoardTool.shared.tasks)) ?? Data()
        let decisionsData = (try? encoder.encode(DecisionEngineTool.shared.decisions)) ?? Data()

        let snapshot = Snapshot(
            id: UUID(),
            label: label,
            createdAt: Date(),
            spacesData: spacesData,
            tasksData: tasksData,
            decisionsData: decisionsData,
            notes: notes
        )
        snapshots.insert(snapshot, at: 0)
        // Keep last 50 snapshots
        if snapshots.count > 50 { snapshots = Array(snapshots.prefix(50)) }
        saveData()
    }

    // MARK: - Restore

    func restoreSnapshot(_ snapshot: Snapshot) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let spaces = try? decoder.decode([CollaborationSpace].self, from: snapshot.spacesData) {
            CollaborationManager.shared.restoreSpaces(spaces)
        }
        if let tasks = try? decoder.decode([ProjectExecutionBoardTool.BoardTask].self, from: snapshot.tasksData) {
            ProjectExecutionBoardTool.shared.restoreTasks(tasks)
        }
        if let decisions = try? decoder.decode([DecisionEngineTool.Decision].self, from: snapshot.decisionsData) {
            DecisionEngineTool.shared.restoreDecisions(decisions)
        }
    }

    // MARK: - Diff

    func diff(snapshotA: Snapshot, snapshotB: Snapshot) -> [SnapshotDiff] {
        var diffs: [SnapshotDiff] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let spacesA = (try? decoder.decode([CollaborationSpace].self, from: snapshotA.spacesData)) ?? []
        let spacesB = (try? decoder.decode([CollaborationSpace].self, from: snapshotB.spacesData)) ?? []

        diffs.append(SnapshotDiff(field: "Space Count", before: "\(spacesA.count)", after: "\(spacesB.count)"))

        let allIDs = Set(spacesA.map { $0.id }).union(spacesB.map { $0.id })
        for id in allIDs {
            let a = spacesA.first { $0.id == id }
            let b = spacesB.first { $0.id == id }
            if let a = a, let b = b {
                if a.name != b.name {
                    diffs.append(SnapshotDiff(field: "Space '\(a.name)' name", before: a.name, after: b.name))
                }
                if a.activityFeed.count != b.activityFeed.count {
                    diffs.append(SnapshotDiff(field: "Space '\(a.name)' activity entries", before: "\(a.activityFeed.count)", after: "\(b.activityFeed.count)"))
                }
            } else if let a = a {
                diffs.append(SnapshotDiff(field: "Space removed", before: a.name, after: "(removed)"))
            } else if let b = b {
                diffs.append(SnapshotDiff(field: "Space added", before: "(new)", after: b.name))
            }
        }

        let tasksA = (try? decoder.decode([ProjectExecutionBoardTool.BoardTask].self, from: snapshotA.tasksData)) ?? []
        let tasksB = (try? decoder.decode([ProjectExecutionBoardTool.BoardTask].self, from: snapshotB.tasksData)) ?? []
        diffs.append(SnapshotDiff(field: "Task Count", before: "\(tasksA.count)", after: "\(tasksB.count)"))

        return diffs
    }

    func deleteSnapshot(id: UUID) {
        snapshots.removeAll { $0.id == id }
        saveData()
    }

    // MARK: - Persistence

    private func saveData() {
        let s = snapshots
        DispatchQueue.global(qos: .utility).async {
            try? WorkspacePersistence.shared.save(s, to: self.storageFile)
        }
    }

    private func loadData() {
        if WorkspacePersistence.shared.exists(filename: storageFile) {
            snapshots = (try? WorkspacePersistence.shared.load([Snapshot].self, from: storageFile)) ?? []
        }
    }
}

// MARK: - Restore helpers on managers

extension CollaborationManager {
    func restoreSpaces(_ spaces: [CollaborationSpace]) {
        self.spaces = spaces
        saveData()
    }
}

extension ProjectExecutionBoardTool {
    func restoreTasks(_ tasks: [BoardTask]) {
        self.tasks = tasks
        try? WorkspacePersistence.shared.save(tasks, to: "collaboration_tasks.json")
    }
}

extension DecisionEngineTool {
    func restoreDecisions(_ decisions: [Decision]) {
        self.decisions = decisions
        try? WorkspacePersistence.shared.save(decisions, to: "collaboration_decisions.json")
    }
}
