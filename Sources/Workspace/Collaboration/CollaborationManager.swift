import Foundation
import Combine

/// Manages collaboration spaces, members, and version control operations.
final class CollaborationManager: ObservableObject {
    static let shared = CollaborationManager()

    @Published var spaces: [CollaborationSpace] = []
    @Published var commits: [UUID: CollaborationCommit] = [:]

    private let spacesFile = "collaboration_spaces.json"
    private let commitsFile = "collaboration_commits.json"

    private init() {
        loadData()
    }

    // MARK: - Space Management

    func createSpace(name: String, description: String, icon: String, visibility: SpaceVisibility) -> CollaborationSpace {
        let spaceID = UUID()
        let initialCommitID = UUID()

        let initialCommit = CollaborationCommit(
            id: initialCommitID,
            parentID: nil,
            message: "Initial commit",
            timestamp: Date(),
            author: "System",
            authorID: UUID(),
            dataSnapshot: Data()
        )
        commits[initialCommitID] = initialCommit

        let initialBranch = CollaborationBranch(id: UUID(), name: "main", headCommitID: initialCommitID)
        let space = CollaborationSpace(
            id: spaceID,
            name: name,
            description: description,
            icon: icon,
            visibility: visibility,
            ownerID: UUID(), // Should be real user ID
            members: [],
            branches: [initialBranch],
            currentBranchID: initialBranch.id,
            activityFeed: [],
            notebookIDs: [],
            slideDeckIDs: [],
            meetingIDs: [],
            formIDs: [],
            spreadsheetIDs: [],
            mediaProjectIDs: [],
            taskIDs: [],
            decisionIDs: [],
            createdAt: Date(),
            updatedAt: Date(),
            metadata: [:]
        )
        spaces.append(space)
        saveData()
        logActivity(spaceID: space.id, action: "Created space '\(name)'")
        return space
    }

    func deleteSpace(id: UUID) {
        spaces.removeAll { $0.id == id }
        saveData()
    }

    // MARK: - Version Control

    func createCommit(spaceID: UUID, branchID: UUID, message: String, data: Data) {
        guard let spaceIndex = spaces.firstIndex(where: { $0.id == spaceID }),
              let branchIndex = spaces[spaceIndex].branches.firstIndex(where: { $0.id == branchID }) else { return }

        let parentID = spaces[spaceIndex].branches[branchIndex].headCommitID
        let commit = CollaborationCommit(
            id: UUID(),
            parentID: parentID,
            message: message,
            timestamp: Date(),
            author: "Local User",
            authorID: UUID(), // Should be real user ID
            dataSnapshot: data
        )

        commits[commit.id] = commit
        spaces[spaceIndex].branches[branchIndex].headCommitID = commit.id
        spaces[spaceIndex].updatedAt = Date()

        logActivity(spaceID: spaceID, action: "Committed: \(message)")
        saveData()
    }

    func createBranch(spaceID: UUID, sourceBranchID: UUID, name: String) {
        guard let spaceIndex = spaces.firstIndex(where: { $0.id == spaceID }),
              let sourceBranch = spaces[spaceIndex].branches.first(where: { $0.id == sourceBranchID }) else { return }

        let newBranch = CollaborationBranch(id: UUID(), name: name, headCommitID: sourceBranch.headCommitID)
        spaces[spaceIndex].branches.append(newBranch)
        saveData()
        logActivity(spaceID: spaceID, action: "Created branch '\(name)' from '\(sourceBranch.name)'")
    }

    func mergeBranch(spaceID: UUID, sourceBranchID: UUID, targetBranchID: UUID) {
        guard let spaceIndex = spaces.firstIndex(where: { $0.id == spaceID }),
              let sourceBranch = spaces[spaceIndex].branches.first(where: { $0.id == sourceBranchID }),
              let targetBranchIndex = spaces[spaceIndex].branches.firstIndex(where: { $0.id == targetBranchID }) else { return }

        // Basic conflict detection: check if target has moved ahead since source branched off
        // For now, we'll just fast-forward or merge the head.
        let sourceHead = sourceBranch.headCommitID
        spaces[spaceIndex].branches[targetBranchIndex].headCommitID = sourceHead
        spaces[spaceIndex].updatedAt = Date()

        saveData()
        logActivity(spaceID: spaceID, action: "Merged branch '\(sourceBranch.name)' into '\(spaces[spaceIndex].branches[targetBranchIndex].name)'")
    }

    func getCommitHistory(branchID: UUID) -> [CollaborationCommit] {
        var history: [CollaborationCommit] = []
        // Find any branch with this ID to get the head
        var currentCommitID: UUID? = nil
        for space in spaces {
            if let branch = space.branches.first(where: { $0.id == branchID }) {
                currentCommitID = branch.headCommitID
                break
            }
        }

        while let id = currentCommitID, let commit = commits[id] {
            history.append(commit)
            currentCommitID = commit.parentID
        }

        return history
    }

    func revertToCommit(spaceID: UUID, branchID: UUID, commitID: UUID) {
        guard let spaceIndex = spaces.firstIndex(where: { $0.id == spaceID }),
              let branchIndex = spaces[spaceIndex].branches.firstIndex(where: { $0.id == branchID }),
              let _ = commits[commitID] else { return }

        spaces[spaceIndex].branches[branchIndex].headCommitID = commitID
        spaces[spaceIndex].updatedAt = Date()

        saveData()
        logActivity(spaceID: spaceID, action: "Reverted branch '\(spaces[spaceIndex].branches[branchIndex].name)' to commit \(commitID.uuidString.prefix(8))")
    }

    // MARK: - Persistence

    private func saveData() {
        do {
            try WorkspacePersistence.shared.save(spaces, to: spacesFile)
            try WorkspacePersistence.shared.save(commits, to: commitsFile)
        } catch {
            print("Error saving collaboration data: \(error)")
        }
    }

    private func loadData() {
        do {
            if WorkspacePersistence.shared.exists(filename: spacesFile) {
                spaces = try WorkspacePersistence.shared.load([CollaborationSpace].self, from: spacesFile)
            }
            if WorkspacePersistence.shared.exists(filename: commitsFile) {
                commits = try WorkspacePersistence.shared.load([UUID: CollaborationCommit].self, from: commitsFile)
            }
        } catch {
            print("Error loading collaboration data: \(error)")
        }
    }

    private func logActivity(spaceID: UUID, action: String) {
        guard let index = spaces.firstIndex(where: { $0.id == spaceID }) else { return }
        let log = ActivityLog(
            id: UUID(),
            timestamp: Date(),
            userID: UUID(), // Real user ID
            userName: "Local User",
            action: action,
            objectID: nil,
            objectType: nil
        )
        spaces[index].activityFeed.insert(log, at: 0)
    }
}
