import Foundation

/// Controller for cross-space administrative operations.
final class CommandCenterController: ObservableObject {
    static let shared = CommandCenterController()

    private init() {}

    /// Performs bulk permission updates across multiple spaces.
    func bulkUpdatePermissions(spaceIDs: [UUID], role: SpaceRole) {
        // Logic to iterate spaces and update permissions for current user
    }

    /// Fetches a unified list of all pending merges across all spaces.
    func getAllPendingMerges() -> [PullRequest] {
        return PRManager.shared.pullRequests.filter { $0.status == .open }
    }

    /// Aggregates audit logs across the entire platform.
    func getGlobalAuditLogs() -> [ActivityLog] {
        return CollaborationManager.shared.spaces.flatMap { $0.activityFeed }.sorted { $0.timestamp > $1.timestamp }
    }
}
