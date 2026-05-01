import Foundation
import Combine

/// Manages pull request operations: creation, review, and merging.
final class PRManager: ObservableObject {
    static let shared = PRManager()

    @Published var pullRequests: [PullRequest] = []

    private let storageKey = "com.tools-kit.collaboration.prs"

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
            authorID: UUID(), // Should be real user ID
            authorName: "Local User",
            status: .open,
            reviewers: [],
            reviews: [],
            comments: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        pullRequests.append(pr)
        savePRs()
        return pr
    }

    func mergePullRequest(id: UUID) async throws {
        guard let index = pullRequests.firstIndex(where: { $0.id == id }) else { return }

        // 1. Validate approvals (if branch protection is on)
        // 2. Perform merge logic via CollaborationManager

        await MainActor.run {
            pullRequests[index].status = .merged
            pullRequests[index].mergedAt = Date()
            savePRs()
        }
    }

    func addComment(prID: UUID, content: String, objectID: UUID? = nil) {
        guard let index = pullRequests.firstIndex(where: { $0.id == prID }) else { return }
        let comment = PRComment(
            id: UUID(),
            authorID: UUID(),
            authorName: "Local User",
            content: content,
            timestamp: Date(),
            objectID: objectID
        )
        pullRequests[index].comments.append(comment)
        savePRs()
    }

    // MARK: - Persistence

    private func savePRs() {
        try? WorkspacePersistence.shared.save(pullRequests, filename: "pull_requests.json")
    }

    private func loadPRs() {
        if let decoded = try? WorkspacePersistence.shared.load(filename: "pull_requests.json", as: [PullRequest].self) {
            pullRequests = decoded
        }
    }
}
