import Foundation
import Combine

/// Status of a Pull Request.
enum PullRequestStatus: String, Codable {
    case open
    case merged
    case closed
    case draft
}

/// Represents a review for a Pull Request.
struct PRReview: Codable, Identifiable {
    let id: UUID
    let reviewerID: UUID
    let reviewerName: String
    var comment: String
    var isApproved: Bool
    let timestamp: Date
}

/// Represents a Pull Request for a workspace object or space.
struct PullRequest: Codable, Identifiable {
    let id: UUID
    let spaceID: UUID
    var title: String
    var description: String
    let sourceBranchID: UUID
    let targetBranchID: UUID
    var status: PullRequestStatus
    let creatorID: UUID
    let creatorName: String
    var reviewers: [UUID]
    var reviews: [PRReview]
    var labels: [String]
    let createdAt: Date
    var updatedAt: Date
}

/// Manages the lifecycle of Pull Requests in a Collaboration Space.
final class PullRequestManager: ObservableObject {
    static let shared = PullRequestManager()

    @Published var pullRequests: [UUID: [PullRequest]] = [:] // spaceID: [PRs]

    private init() {}

    func createPullRequest(spaceID: UUID, title: String, description: String, sourceBranchID: UUID, targetBranchID: UUID) -> PullRequest {
        let pr = PullRequest(
            id: UUID(),
            spaceID: spaceID,
            title: title,
            description: description,
            sourceBranchID: sourceBranchID,
            targetBranchID: targetBranchID,
            status: .open,
            creatorID: UUID(), // Placeholder
            creatorName: "Local User",
            reviewers: [],
            reviews: [],
            labels: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        if pullRequests[spaceID] != nil {
            pullRequests[spaceID]?.append(pr)
        } else {
            pullRequests[spaceID] = [pr]
        }

        return pr
    }

    func mergePullRequest(prID: UUID, spaceID: UUID) {
        guard let index = pullRequests[spaceID]?.firstIndex(where: { $0.id == prID }) else { return }
        pullRequests[spaceID]?[index].status = .merged
        pullRequests[spaceID]?[index].updatedAt = Date()

        // Logic for merging branch data in CollaborationManager would go here
        print("PR \(prID) merged in space \(spaceID)")
    }
}
