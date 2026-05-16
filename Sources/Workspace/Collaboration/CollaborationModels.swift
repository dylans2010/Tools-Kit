import Foundation

/// Defines the visibility of a Collaboration Space or Channel.
enum CollaborationVisibility: String, Codable {
    case publicChannel = "Public"
    case privateChannel = "Private"
    case directMessage = "Direct"
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
