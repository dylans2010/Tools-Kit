import Foundation
import Combine
import SwiftUI

/// Rebuilt Collaboration Manager for Collaboration 2.0 System.
@MainActor
final class CollaborationManager: ObservableObject {
    static let shared = CollaborationManager()

    @Published var workspaces: [CollaborationWorkspace] = []
    @Published var spaces: [CollaborationSpace] = []
    @Published var activeWorkspaceID: UUID?
    @Published var activeChannelID: UUID?
    @Published var presence: [UUID: CollaborationPresence] = [:]
    @Published var commits: [UUID: CollaborationCommit] = [:]

    private let workspacesFile = "collaboration_workspaces_v2.json"
    private let commitsFile = "collaboration_commits_v2.json"
    private let spacesFile = "collaboration_spaces_v2.json"
    private let dataStore = UnifiedDataStore.shared

    private init() {
        loadWorkspaces()
        loadSpaces()
    }

    // MARK: - Workspace & Channel Management

    func createWorkspace(name: String, description: String, icon: String) -> CollaborationWorkspace {
        let workspaceID = UUID()
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

        let workspace = CollaborationWorkspace(
            id: workspaceID,
            name: name,
            description: description,
            icon: icon,
            ownerID: UUID(), // Current user ID
            members: [],
            channels: [
                CollaborationChannel(
                    id: UUID(),
                    name: "general",
                    type: .publicChannel,
                    description: "Workspace-wide discussion",
                    messages: [],
                    memberIDs: [],
                    lastReadTimestamp: Date()
                )
            ],
            branches: [initialBranch],
            currentBranchID: initialBranch.id,
            createdAt: Date(),
            updatedAt: Date()
        )
        workspaces.append(workspace)
        saveWorkspaces()
        saveCommits()
        logActivity(workspaceID: workspace.id, action: "Created workspace '\(name)'")
        return workspace
    }

    func selectWorkspace(_ workspaceID: UUID) {
        activeWorkspaceID = workspaceID
        if let workspace = workspaces.first(where: { $0.id == workspaceID }) {
            activeChannelID = workspace.channels.first?.id
        }
    }

    func selectChannel(_ channelID: UUID) {
        activeChannelID = channelID
    }

    // MARK: - Permissions

    func userHasPermission(workspaceID: UUID, permission: CollaborationRole) -> Bool {
        guard let workspace = workspaces.first(where: { $0.id == workspaceID }) else { return false }
        // For local demo, we assume admin
        return true
    }

    // MARK: - Version Control (Legacy Restoration)

    func createCommit(workspaceID: UUID, branchID: UUID, message: String, data: Data) {
        guard let wIdx = workspaces.firstIndex(where: { $0.id == workspaceID }),
              let bIdx = workspaces[wIdx].branches.firstIndex(where: { $0.id == branchID }) else { return }

        let parentID = workspaces[wIdx].branches[bIdx].headCommitID
        let commit = CollaborationCommit(
            id: UUID(),
            parentID: parentID,
            message: message,
            timestamp: Date(),
            author: "Local User",
            authorID: UUID(),
            dataSnapshot: data
        )

        commits[commit.id] = commit
        workspaces[wIdx].branches[bIdx].headCommitID = commit.id
        workspaces[wIdx].updatedAt = Date()

        logActivity(workspaceID: workspaceID, action: "Committed: \(message)")
        saveWorkspaces()
        saveCommits()
    }

    func createBranch(workspaceID: UUID, sourceBranchID: UUID, name: String) {
        guard let wIdx = workspaces.firstIndex(where: { $0.id == workspaceID }),
              let sourceBranch = workspaces[wIdx].branches.first(where: { $0.id == sourceBranchID }) else { return }

        let newBranch = CollaborationBranch(id: UUID(), name: name, headCommitID: sourceBranch.headCommitID)
        workspaces[wIdx].branches.append(newBranch)
        saveWorkspaces()
        logActivity(workspaceID: workspaceID, action: "Created branch '\(name)' from '\(sourceBranch.name)'")
    }

    func getCommitHistory(branchID: UUID) -> [CollaborationCommit] {
        var history: [CollaborationCommit] = []
        var currentCommitID: UUID? = nil

        for workspace in workspaces {
            if let branch = workspace.branches.first(where: { $0.id == branchID }) {
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

    private func logActivity(workspaceID: UUID, action: String) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspaceID }) else { return }
        let log = ActivityLog(
            id: UUID(),
            timestamp: Date(),
            userID: UUID(),
            userName: "Local User",
            action: action,
            objectID: nil,
            objectType: nil
        )
        workspaces[index].activityFeed.insert(log, at: 0)
    }

    // MARK: - Messaging & Threads

    func sendMessage(content: String, channelID: UUID, workspaceID: UUID) {
        guard let wIdx = workspaces.firstIndex(where: { $0.id == workspaceID }),
              let cIdx = workspaces[wIdx].channels.firstIndex(where: { $0.id == channelID }) else { return }

        let message = CollaborationMessage(
            id: UUID(),
            senderID: UUID(), // Current user ID
            senderName: "Local User",
            content: content,
            timestamp: Date()
        )

        workspaces[wIdx].channels[cIdx].messages.append(message)
        logActivity(workspaceID: workspaceID, action: "New message in #\(workspaces[wIdx].channels[cIdx].name)")
        saveWorkspaces()
    }

    func sendReply(content: String, parentMessageID: UUID, channelID: UUID, workspaceID: UUID) {
        guard let wIdx = workspaces.firstIndex(where: { $0.id == workspaceID }),
              let cIdx = workspaces[wIdx].channels.firstIndex(where: { $0.id == channelID }),
              let mIdx = workspaces[wIdx].channels[cIdx].messages.firstIndex(where: { $0.id == parentMessageID }) else { return }

        let reply = CollaborationMessage(
            id: UUID(),
            senderID: UUID(),
            senderName: "Local User",
            content: content,
            timestamp: Date()
        )

        if workspaces[wIdx].channels[cIdx].messages[mIdx].thread == nil {
            workspaces[wIdx].channels[cIdx].messages[mIdx].thread = CollaborationThread(
                id: UUID(),
                parentMessageID: parentMessageID,
                replies: []
            )
        }

        workspaces[wIdx].channels[cIdx].messages[mIdx].thread?.replies.append(reply)
        logActivity(workspaceID: workspaceID, action: "New reply in #\(workspaces[wIdx].channels[cIdx].name)")
        saveWorkspaces()
    }

    // MARK: - Presence

    func updatePresence(userID: UUID, status: PresenceStatus) {
        presence[userID] = CollaborationPresence(
            userID: userID,
            status: status,
            lastActive: Date()
        )

        if status == .typing {
            // Auto-clear typing status after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                if presence[userID]?.status == .typing {
                    presence[userID]?.status = .online
                }
            }
        }
    }

    // MARK: - Space Management

    func createSpace(name: String, description: String, icon: String, visibility: SpaceVisibility) -> CollaborationSpace {
        let space = CollaborationSpace(
            id: UUID(),
            name: name,
            description: description,
            icon: icon,
            visibility: visibility,
            ownerID: UUID(),
            members: [],
            currentBranchID: UUID(),
            createdAt: Date(),
            updatedAt: Date()
        )
        spaces.append(space)
        saveSpaces()
        return space
    }

    func deleteSpace(id: UUID) {
        spaces.removeAll { $0.id == id }
        saveSpaces()
    }

    func revertToCommit(spaceID: UUID, branchID: UUID, commitID: UUID) {
        guard let wIdx = workspaces.firstIndex(where: { $0.id == spaceID }),
              let bIdx = workspaces[wIdx].branches.firstIndex(where: { $0.id == branchID }),
              commits[commitID] != nil else { return }
        workspaces[wIdx].branches[bIdx].headCommitID = commitID
        logActivity(workspaceID: spaceID, action: "Reverted to commit \(commitID.uuidString.prefix(8))")
        saveWorkspaces()
    }

    func mergeBranch(spaceID: UUID, sourceBranchID: UUID, targetBranchID: UUID) {
        guard let wIdx = workspaces.firstIndex(where: { $0.id == spaceID }),
              let sourceBranch = workspaces[wIdx].branches.first(where: { $0.id == sourceBranchID }),
              let tIdx = workspaces[wIdx].branches.firstIndex(where: { $0.id == targetBranchID }) else { return }
        workspaces[wIdx].branches[tIdx].headCommitID = sourceBranch.headCommitID
        logActivity(workspaceID: spaceID, action: "Merged branch into target")
        saveWorkspaces()
    }

    // MARK: - Persistence

    func saveData() {
        saveSpaces()
    }

    private func saveWorkspaces() {
        try? dataStore.save(workspaces, key: workspacesFile)
    }

    private func saveCommits() {
        try? dataStore.save(commits, key: commitsFile)
    }

    private func saveSpaces() {
        try? dataStore.save(spaces, key: spacesFile)
    }

    private func loadSpaces() {
        if let loaded = try? dataStore.load([CollaborationSpace].self, key: spacesFile) {
            self.spaces = loaded
        }
        if spaces.isEmpty {
            let defaultSpace = CollaborationSpace(
                id: UUID(),
                name: "Default Space",
                description: "Your primary collaboration space",
                icon: "briefcase.fill",
                visibility: .privateSpace,
                ownerID: UUID(),
                members: [],
                currentBranchID: UUID(),
                createdAt: Date(),
                updatedAt: Date()
            )
            spaces.append(defaultSpace)
        }
    }

    private func loadWorkspaces() {
        if let loaded = try? dataStore.load([CollaborationWorkspace].self, key: workspacesFile) {
            self.workspaces = loaded
        }
        if let loadedCommits = try? dataStore.load([UUID: CollaborationCommit].self, key: commitsFile) {
            self.commits = loadedCommits
        }

        if workspaces.isEmpty {
            _ = createWorkspace(name: "Default Workspace", description: "Your primary collaboration space", icon: "briefcase.fill")
        }
        activeWorkspaceID = workspaces.first?.id
        activeChannelID = workspaces.first?.channels.first?.id
    }
}
