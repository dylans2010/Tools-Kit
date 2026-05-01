import Foundation

struct WorkspacePullRequest: Identifiable {
    enum Status: String { case open, approved, rejected, merged }
    let id: UUID
    let spaceID: UUID
    var title: String
    var sourceBranch: String
    var targetBranch: String
    var reviewers: [String]
    var requiredApprovals: Int
    var approvals: Set<String>
    var inlineThreads: [String]
    var status: Status
}

final class PullRequestService {
    static let shared = PullRequestService()
    private(set) var pullRequests: [WorkspacePullRequest] = []

    func create(spaceID: UUID, title: String, sourceBranch: String, targetBranch: String, reviewers: [String], requiredApprovals: Int) -> WorkspacePullRequest {
        let pr = WorkspacePullRequest(id: UUID(), spaceID: spaceID, title: title, sourceBranch: sourceBranch, targetBranch: targetBranch, reviewers: reviewers, requiredApprovals: requiredApprovals, approvals: [], inlineThreads: [], status: .open)
        pullRequests.insert(pr, at: 0)
        return pr
    }
}
