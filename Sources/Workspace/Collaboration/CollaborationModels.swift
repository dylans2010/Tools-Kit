import Foundation

/// Defines the visibility of a Collaboration Space or Channel.
enum CollaborationVisibility: String, Codable {
    case publicChannel = "Public"
    case privateChannel = "Private"
    case directMessage = "Direct"
}

/// Defines the visibility of a Collaboration Space.
enum SpaceVisibility: String, Codable {
    case shared = "Shared"
    case privateSpace = "Private"
}

/// Defines the roles within a Collaboration Space.
enum SpaceRole: String, Codable {
    case owner = "Owner"
    case admin = "Admin"
    case editor = "Editor"
    case commenter = "Commenter"
    case viewer = "Viewer"
}

/// A member of a Collaboration Space.
struct SpaceMember: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    var role: SpaceRole
}

/// A message within a Collaboration Space.
struct SpaceMessage: Codable, Identifiable {
    let id: UUID
    let senderID: UUID
    let senderName: String
    let content: String
    let timestamp: Date
}

/// A file shared within a Collaboration Space.
struct SpaceFile: Codable, Identifiable {
    let id: UUID
    let name: String
    let size: Int64
    let type: String
    let uploaderID: UUID
    let timestamp: Date
    let localPath: String?
}

/// A branch within a Collaboration Workspace or Space.
struct CollaborationBranch: Codable, Identifiable {
    let id: UUID
    var name: String
    var headCommitID: UUID
    var isProtected: Bool = false
}

/// A commit within the version control system.
struct CollaborationCommit: Codable, Identifiable {
    let id: UUID
    let parentID: UUID?
    let message: String
    let timestamp: Date
    let author: String
    let authorID: UUID
    let dataSnapshot: Data
}

/// An activity log entry within a Collaboration Workspace or Space.
struct ActivityLog: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let userID: UUID
    let userName: String
    let action: String
    let objectID: UUID?
    let objectType: String?
}

/// A top-level Collaboration Space with messaging, files, members, and version control.
struct CollaborationSpace: Codable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var icon: String
    var visibility: SpaceVisibility
    var ownerID: UUID
    var members: [SpaceMember]
    var messages: [SpaceMessage] = []
    var sharedFiles: [SpaceFile] = []
    var branches: [CollaborationBranch] = []
    var currentBranchID: UUID
    var activityFeed: [ActivityLog] = []
    var activeUsers: [UUID] = []
    var notebookIDs: [UUID] = []
    var slideDeckIDs: [UUID] = []
    var meetingIDs: [UUID] = []
    var formIDs: [UUID] = []
    var spreadsheetIDs: [UUID] = []
    var mediaProjectIDs: [UUID] = []
    var taskIDs: [UUID] = []
    var decisionIDs: [UUID] = []
    var createdAt: Date
    var updatedAt: Date
}

/// Defines the roles within a Collaboration System.
enum CollaborationRole: String, Codable {
    case admin = "Admin"
    case member = "Member"
    case viewer = "Viewer"
}

/// Represents a user's presence status.
enum PresenceStatus: String, Codable {
    case online = "Online"
    case offline = "Offline"
    case typing = "Typing"
}

/// Represents a member's permission and role.
struct CollaborationMember: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    var role: CollaborationRole
}

/// A workspace containing multiple channels.
struct CollaborationWorkspace: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var icon: String
    var ownerID: UUID
    var members: [CollaborationMember]
    var channels: [CollaborationChannel]
    var branches: [CollaborationBranch] = []
    var currentBranchID: UUID?
    var activityFeed: [ActivityLog] = []
    var sharedFiles: [SpaceFile] = []

    // Legacy linked object IDs
    var notebookIDs: [UUID] = []
    var slideDeckIDs: [UUID] = []
    var meetingIDs: [UUID] = []
    var formIDs: [UUID] = []
    var spreadsheetIDs: [UUID] = []
    var mediaProjectIDs: [UUID] = []
    var taskIDs: [UUID] = []
    var decisionIDs: [UUID] = []

    var createdAt: Date
    var updatedAt: Date
}

/// A channel within a workspace (Public, Private, or DM).
struct CollaborationChannel: Codable, Identifiable {
    let id: UUID
    var name: String
    var type: CollaborationVisibility
    var description: String
    var messages: [CollaborationMessage]
    var memberIDs: [UUID]
    var isMuted: Bool = false
    var lastReadTimestamp: Date
}

/// A message in a channel, capable of spawning a thread.
struct CollaborationMessage: Codable, Identifiable {
    let id: UUID
    let senderID: UUID
    let senderName: String
    let content: String
    let timestamp: Date
    var attachments: [CollaborationAttachment] = []
    var thread: CollaborationThread?
}

/// A threaded conversation nested under a message.
struct CollaborationThread: Codable, Identifiable {
    let id: UUID
    let parentMessageID: UUID
    var replies: [CollaborationMessage]
}

/// Attachment metadata for a message.
struct CollaborationAttachment: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: String
    let size: Int64
    let url: String
    let metadata: [String: String]
}

/// Real-time presence information.
struct CollaborationPresence: Codable {
    let userID: UUID
    var status: PresenceStatus
    var lastActive: Date
}
