import Foundation

/// Defines the visibility of a Collaboration Space.
enum SpaceVisibility: String, Codable {
    case privateSpace = "Private"
    case shared = "Shared"
    case publicSpace = "Public"
}

/// Defines the roles within a Collaboration Space.
enum SpaceRole: String, Codable {
    case owner = "Owner"
    case admin = "Admin"
    case editor = "Editor"
    case commenter = "Commenter"
    case viewer = "Viewer"
}

/// Represents a member of a Collaboration Space.
struct SpaceMember: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    var role: SpaceRole
}

/// Represents a commit in the version control system.
struct CollaborationCommit: Codable, Identifiable {
    let id: UUID
    let parentID: UUID?
    let message: String
    let timestamp: Date
    let author: String
    let authorID: UUID
    let dataSnapshot: Data // Encoded state of the workspace objects
}

/// Represents a branch in the version control system.
struct CollaborationBranch: Codable, Identifiable {
    let id: UUID
    var name: String
    var headCommitID: UUID
    var isProtected: Bool = false
}

/// Represents an activity entry in the space's feed.
struct ActivityLog: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let userID: UUID
    let userName: String
    let action: String
    let objectID: UUID?
    let objectType: String?
}

/// The core container for a Collaboration Space.
struct CollaborationSpace: Codable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var icon: String
    var visibility: SpaceVisibility
    var ownerID: UUID
    var members: [SpaceMember]
    var branches: [CollaborationBranch]
    var currentBranchID: UUID
    var activityFeed: [ActivityLog]
    var messages: [SpaceMessage] = []
    var sharedFiles: [SpaceFile] = []
    var activeUsers: [String] = []

    // IDs of objects linked to this space
    var notebookIDs: [UUID]
    var slideDeckIDs: [UUID]
    var meetingIDs: [UUID]
    var formIDs: [UUID]
    var spreadsheetIDs: [UUID]
    var mediaProjectIDs: [UUID]

    // Tool states
    var taskIDs: [UUID]
    var decisionIDs: [UUID]

    var createdAt: Date
    var updatedAt: Date
    var metadata: [String: String] = [:]
}

struct SpaceMessage: Codable, Identifiable {
    let id: UUID
    let senderID: UUID
    let senderName: String
    let content: String
    let timestamp: Date
}

struct SpaceFile: Codable, Identifiable {
    let id: UUID
    let name: String
    let size: Int64
    let type: String
    let uploaderID: UUID
    let timestamp: Date
    let localPath: String?
}
