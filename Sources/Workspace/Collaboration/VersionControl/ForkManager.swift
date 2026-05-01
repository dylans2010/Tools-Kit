import Foundation
import Combine

/// Manages forking of Collaboration Spaces.
final class ForkManager: ObservableObject {
    static let shared = ForkManager()

    @Published var forks: [UUID: UUID] = [:] // forkID: parentID

    private init() {}

    /// Forks a space and creates an independent version history.
    func forkSpace(spaceID: UUID) -> CollaborationSpace? {
        guard let parentSpace = CollaborationManager.shared.spaces.first(where: { $0.id == spaceID }) else { return nil }

        var forkedSpace = parentSpace
        forkedSpace.id = UUID()
        forkedSpace.name = "\(parentSpace.name) (Fork)"
        forkedSpace.createdAt = Date()
        forkedSpace.updatedAt = Date()
        forkedSpace.activityFeed = [
            ActivityLog(id: UUID(), timestamp: Date(), userID: UUID(), userName: "Local User", action: "Forked from \(parentSpace.name)", objectID: parentSpace.id, objectType: "Space")
        ]

        CollaborationManager.shared.spaces.append(forkedSpace)
        forks[forkedSpace.id] = parentSpace.id

        return forkedSpace
    }

    /// Compares a fork with its upstream parent.
    func compareWithUpstream(forkID: UUID) -> String {
        guard let parentID = forks[forkID] else { return "No upstream found." }
        return "Comparing fork \(forkID) with original space \(parentID)"
    }
}
