import Foundation

enum ProjectStatus: String, Codable, CaseIterable, Sendable {
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case archived = "Archived"
}

enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"
}

struct Project: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var iconName: String = "folder.fill"
    var colorHex: String = "007AFF"
    var status: ProjectStatus = .active
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var tasks: [ProjectTask] = []
    var files: [ProjectFile] = []
    var annotations: [ProjectAnnotation] = []
    var collaborators: [ProjectCollaborator] = []
    var linkedChatIDs: [UUID] = []
    var settings: ProjectSettings = ProjectSettings()
}

struct ProjectTask: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var title: String
    var description: String = ""
    var status: TaskStatus = .todo
    var priority: TaskPriority = .medium
    var dueDate: Date?
    var assignedTo: String = ""
    var createdAt: Date = Date()
    var tags: [String] = []

    enum TaskPriority: String, Codable, CaseIterable, Sendable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
}

struct ProjectFile: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var fileName: String
    var mimeType: String
    var data: Data
    var addedAt: Date = Date()
    var addedBy: String = "You"
    var note: String = ""
}

struct ProjectAnnotation: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var content: String
    var author: String = "You"
    var createdAt: Date = Date()
    var tags: [String] = []
}

struct ProjectCollaborator: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var role: CollaboratorRole = .member
    var joinedAt: Date = Date()
    var avatarInitials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

enum CollaboratorRole: String, Codable, CaseIterable, Sendable {
    case owner = "Owner"
    case admin = "Admin"
    case member = "Member"
    case viewer = "Viewer"
}

struct ProjectSettings: Codable, Sendable {
    var allowFileUploads: Bool = true
    var allowAnnotations: Bool = true
    var defaultTaskPriority: ProjectTask.TaskPriority = .medium
    var notificationsEnabled: Bool = true
    var isPublic: Bool = false
    var tags: [String] = []
}

struct LinkedChat: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var title: String
    var summary: String
    var messages: [ChatMessage]
    var addedAt: Date = Date()
}
