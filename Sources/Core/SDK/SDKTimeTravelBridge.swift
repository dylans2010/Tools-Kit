import Foundation
import Combine

@MainActor
public final class SDKTimeTravelBridge: ObservableObject {
    public static let shared = SDKTimeTravelBridge()

    @Published public var snapshotHistory: [TimeTravelRecord] = []

    private let maxHistorySize = 100

    public struct TimeTravelRecord: Identifiable {
        public let id: UUID
        public let snapshotID: UUID
        public let action: TimeTravelAction
        public let timestamp: Date
        public let details: String

        public enum TimeTravelAction: String {
            case snapshot, restore, diff
        }
    }

    private init() {}

    // MARK: - Get History

    internal func getHistory(scope: SDKScope?, from: Date?, to: Date?) -> [WorkspaceSnapshot] {
        var snapshots = WorkspaceAPI.shared.timeTravel.listSnapshots()

        if let from = from {
            snapshots = snapshots.filter { $0.timestamp >= from }
        }
        if let to = to {
            snapshots = snapshots.filter { $0.timestamp <= to }
        }

        SDKLogStore.shared.log("Retrieved \(snapshots.count) snapshots", source: "SDKTimeTravelBridge", level: .info)
        return snapshots
    }

    // MARK: - Restore

    public func restore(snapshotID: UUID) throws {
        try WorkspaceAPI.shared.timeTravel.restoreState(snapshotID: snapshotID)

        let record = TimeTravelRecord(
            id: UUID(),
            snapshotID: snapshotID,
            action: .restore,
            timestamp: Date(),
            details: "Restored snapshot \(snapshotID)"
        )
        appendRecord(record)

        SDKLogStore.shared.log("Snapshot restored: \(snapshotID)", source: "SDKTimeTravelBridge", level: .info)
    }

    // MARK: - Create Snapshot

    public func createSnapshot(message: String) {
        WorkspaceAPI.shared.timeTravel.createSnapshot(message: message)

        let record = TimeTravelRecord(
            id: UUID(),
            snapshotID: UUID(),
            action: .snapshot,
            timestamp: Date(),
            details: message
        )
        appendRecord(record)

        SDKLogStore.shared.log("Snapshot created: \(message)", source: "SDKTimeTravelBridge", level: .info)
    }

    // MARK: - Diff

    public func diff(snapshotA: UUID, snapshotB: UUID) -> [String: Any] {
        let allSnapshots = WorkspaceAPI.shared.timeTravel.listSnapshots()
        let a = allSnapshots.first { $0.id == snapshotA }
        let b = allSnapshots.first { $0.id == snapshotB }

        var diffResult: [String: Any] = [
            "snapshotA": snapshotA.uuidString,
            "snapshotB": snapshotB.uuidString,
            "foundA": a != nil,
            "foundB": b != nil
        ]

        if let a = a, let b = b {
            diffResult["timeDelta"] = b.timestamp.timeIntervalSince(a.timestamp)
            diffResult["messageA"] = a.message
            diffResult["messageB"] = b.message
        }

        let record = TimeTravelRecord(
            id: UUID(),
            snapshotID: snapshotA,
            action: .diff,
            timestamp: Date(),
            details: "Diff between \(snapshotA) and \(snapshotB)"
        )
        appendRecord(record)

        SDKLogStore.shared.log("Diff computed: \(snapshotA) vs \(snapshotB)", source: "SDKTimeTravelBridge", level: .info)
        return diffResult
    }

    // MARK: - Private

    private func appendRecord(_ record: TimeTravelRecord) {
        snapshotHistory.insert(record, at: 0)
        if snapshotHistory.count > maxHistorySize {
            snapshotHistory = Array(snapshotHistory.prefix(maxHistorySize))
        }
    }
}
