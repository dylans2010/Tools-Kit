import Foundation
import Combine

/// A high-performance, Git-like version control engine for workspace modules.
@MainActor
final class VersionControlManager: ObservableObject {
    nonisolated(unsafe) static let shared = VersionControlManager()

    struct Branch: Codable, Identifiable, Sendable {
        let id: UUID
        var name: String
        var headCommitID: UUID
    }

    struct Commit: Codable, Identifiable, Sendable {
        let id: UUID
        let parentID: UUID?
        let message: String
        let timestamp: Date
        let author: String
        let dataSnapshot: Data // Encoded blocks or scene graph
    }

    @Published var branches: [String: Branch] = [:]
    @Published var commits: [UUID: Commit] = [:]

    private init() {}

    func createCommit(branchName: String, message: String, data: Data) {
        let parentID = branches[branchName]?.headCommitID
        let commit = Commit(id: UUID(), parentID: parentID, message: message, timestamp: Date(), author: "Local User", dataSnapshot: data)
        commits[commit.id] = commit

        if var branch = branches[branchName] {
            branch.headCommitID = commit.id
            branches[branchName] = branch
        } else {
            branches[branchName] = Branch(id: UUID(), name: branchName, headCommitID: commit.id)
        }
    }

    func getHistory(for branchName: String) -> [Commit] {
        guard var nextCommitID = branches[branchName]?.headCommitID else { return [] }
        var history: [Commit] = []

        while let commit = commits[nextCommitID] {
            history.append(commit)
            guard let parentID = commit.parentID else { break }
            nextCommitID = parentID
        }

        return history
    }

    @discardableResult
    func restoreVersion(id: UUID, on branchName: String = "main") -> Data? {
        guard let commit = commits[id] else { return nil }

        if var branch = branches[branchName] {
            branch.headCommitID = id
            branches[branchName] = branch
        } else {
            branches[branchName] = Branch(id: UUID(), name: branchName, headCommitID: id)
        }

        return commit.dataSnapshot
    }

    func diff(commitA: UUID, commitB: UUID) -> String {
        // Semantic diffing logic for blocks
        return "Visual diff between \(commitA) and \(commitB)"
    }
}
