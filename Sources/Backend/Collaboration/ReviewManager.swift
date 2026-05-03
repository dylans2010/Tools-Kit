import Foundation
import Combine

/// Manages the 'Review Mode' for workspace objects.
/// In review mode, objects are locked for editing and only suggestions/comments are allowed.
final class ReviewManager: ObservableObject {
    static let shared = ReviewManager()

    @Published var lockedObjects: Set<UUID> = []

    private init() {}

    /// Locks an object for review.
    func enterReviewMode(objectID: UUID) {
        lockedObjects.insert(objectID)
    }

    /// Unlocks an object.
    func exitReviewMode(objectID: UUID) {
        lockedObjects.remove(objectID)
    }

    /// Checks if an object is currently in review mode.
    func isInReviewMode(objectID: UUID) -> Bool {
        lockedObjects.contains(objectID)
    }

    /// Processes a suggestion (accept/reject).
    func processSuggestion(objectID: UUID, suggestionID: UUID, accepted: Bool) {
        print("Suggestion \(suggestionID) for object \(objectID) was \(accepted ? "accepted" : "rejected")")
    }
}
