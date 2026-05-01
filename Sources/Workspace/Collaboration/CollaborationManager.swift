import Foundation
import Combine

/// Manages collaboration spaces, members, and version control operations.
final class CollaborationManager: ObservableObject {
    static let shared = CollaborationManager()

    @Published var spaces: [CollaborationSpace] = []
    @Published var commits: [UUID: CollaborationCommit] = [:]

    private let storageKey = "com.tools-kit.collaboration.spaces"

    private init() {
        loadSpaces()
    }

    // MARK: - Space Management

    func createSpace(name: String, description: String, icon: String, visibility: SpaceVisibility) -> CollaborationSpace {
        let initialBranch = CollaborationBranch(id: UUID(), name: "main", headCommitID: UUID()) // Dummy head for now
        let space = CollaborationSpace(
            id: UUID(),
            name: name,
            description: description,
            icon: icon,
            visibility: visibility,
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
            createdAt: Date(),
            updatedAt: Date()
        )
        spaces.append(space)
        saveSpaces()
        logActivity(spaceID: space.id, action: "Created space '\(name)'")
        return space
    }

    func deleteSpace(id: UUID) {
        spaces.removeAll { $0.id == id }
        saveSpaces()
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
        saveSpaces()
    }

    func createBranch(spaceID: UUID, sourceBranchID: UUID, name: String) {
        guard let spaceIndex = spaces.firstIndex(where: { $0.id == spaceID }),
              let sourceBranch = spaces[spaceIndex].branches.first(where: { $0.id == sourceBranchID }) else { return }

        let newBranch = CollaborationBranch(id: UUID(), name: name, headCommitID: sourceBranch.headCommitID)
        spaces[spaceIndex].branches.append(newBranch)
        saveSpaces()
        logActivity(spaceID: spaceID, action: "Created branch '\(name)' from '\(sourceBranch.name)'")
    }

    // MARK: - Persistence

    private func saveSpaces() {
        try? WorkspacePersistence.shared.save(spaces, filename: "spaces.json")
    }

    private func loadSpaces() {
        if let decoded = try? WorkspacePersistence.shared.load(filename: "spaces.json", as: [CollaborationSpace].self) {
            spaces = decoded
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
