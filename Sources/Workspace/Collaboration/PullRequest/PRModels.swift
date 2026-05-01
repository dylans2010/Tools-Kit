import Foundation

/// Defines the status of a pull request.
enum PRStatus: String, Codable {
    case open
    case merged
    case closed
    case draft
}

/// Represents a comment on a pull request, optionally linked to a specific change.
struct PRComment: Identifiable, Codable {
    let id: UUID
    let authorID: UUID
    let authorName: String
    let content: String
    let timestamp: Date
    let objectID: UUID? // Optional: link to specific workspace object
}

/// Represents a review for a pull request.
struct PRReview: Identifiable, Codable {
    let id: UUID
    let reviewerID: UUID
    let reviewerName: String
    let status: ReviewStatus
    let timestamp: Date

    enum ReviewStatus: String, Codable {
        case approved
        case changesRequested
        case commented
    }
}

/// The core model for a Pull Request in the Collaboration system.
struct PullRequest: Identifiable, Codable {
    let id: UUID
    let spaceID: UUID
    var title: String
    var description: String
    let sourceBranchID: UUID
    let targetBranchID: UUID
    let authorID: UUID
    let authorName: String
    var status: PRStatus
    var reviewers: [UUID]
    var reviews: [PRReview]
    var comments: [PRComment]

    let createdAt: Date
    var updatedAt: Date
    var mergedAt: Date?
}
