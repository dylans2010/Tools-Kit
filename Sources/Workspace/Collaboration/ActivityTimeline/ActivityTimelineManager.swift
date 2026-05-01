import Foundation

/// Manages the activity feed and history replay for collaboration spaces.
final class ActivityTimelineManager: ObservableObject {
    static let shared = ActivityTimelineManager()

    private init() {}

    /// Filters the activity feed based on criteria.
    func filteredFeed(for space: CollaborationSpace, type: ActivityType?) -> [ActivityLog] {
        guard let type = type else { return space.activityFeed }
        return space.activityFeed.filter { $0.action.contains(type.rawValue) }
    }

    /// Prepares data for replaying history step-by-step.
    func prepareReplaySession(for space: CollaborationSpace) -> [CollaborationCommit] {
        // Logic to sort commits chronologically and prepare state snapshots
        return [] // Implementation for replay mode
    }

    enum ActivityType: String {
        case commit = "Committed"
        case merge = "Merged"
        case comment = "Commented"
        case branch = "Created branch"
    }
}
