import Foundation
import Combine

/// Status of a Pull Request.
enum PullRequestStatus: String, Codable, Sendable {
    case open
    case merged
    case closed
    case draft
}

/// Represents a review for a Pull Request.
struct PRReview: Codable, Identifiable, Sendable {
    let id: UUID
    let reviewerID: UUID
    let reviewerName: String
    var comment: String
    var isApproved: Bool
    let timestamp: Date
}

/// Represents a Pull Request for a workspace object or space.
struct PullRequest: Codable, Identifiable, Sendable {
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
    nonisolated(unsafe) static let shared = PullRequestManager()

    @Published var pullRequests: [UUID: [PullRequest]] = [:] // spaceID: [PRs]

    private let prFile = "collaboration_prs.json"

    private init() {
        loadPRs()
    }

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

        savePRs()
        return pr
    }

    func approvePullRequest(prID: UUID, spaceID: UUID, reviewerID: UUID, reviewerName: String, comment: String) {
        guard let index = pullRequests[spaceID]?.firstIndex(where: { $0.id == prID }) else { return }
        let review = PRReview(id: UUID(), reviewerID: reviewerID, reviewerName: reviewerName, comment: comment, isApproved: true, timestamp: Date())
        pullRequests[spaceID]?[index].reviews.append(review)
        pullRequests[spaceID]?[index].updatedAt = Date()
        savePRs()
    }

    func mergePullRequest(prID: UUID, spaceID: UUID) {
        guard let index = pullRequests[spaceID]?.firstIndex(where: { $0.id == prID }),
              let pr = pullRequests[spaceID]?[index] else { return }

        // Perform actual merge in CollaborationManager
        CollaborationManager.shared.mergeBranch(spaceID: spaceID, sourceBranchID: pr.sourceBranchID, targetBranchID: pr.targetBranchID)

        pullRequests[spaceID]?[index].status = .merged
        pullRequests[spaceID]?[index].updatedAt = Date()
        savePRs()
    }

    // MARK: - Persistence

    private func savePRs() {
        do {
            try WorkspacePersistence.shared.save(pullRequests, to: prFile)
        } catch {
            print("Error saving PRs: \(error)")
        }
    }

    private func loadPRs() {
        do {
            if WorkspacePersistence.shared.exists(filename: prFile) {
                pullRequests = try WorkspacePersistence.shared.load([UUID: [PullRequest]].self, from: prFile)
            }
        } catch {
            print("Error loading PRs: \(error)")
        }
    }
}
