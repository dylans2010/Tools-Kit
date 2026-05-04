import Foundation

// MARK: - Capabilities

enum PluginCapability: String, Codable, CaseIterable, Identifiable {
    case notes
    case mail
    case tasks
    case calendar
    case files
    case whiteboard
    case slides
    case media
    case meet
    case github
    case automation
    case intelligence
    case collaboration
    case spatial
    case search
    case messaging
    case storage
    case analytics
    case ai

    var id: String { rawValue }
}

// MARK: - Actions

enum PluginAction: String, Codable, CaseIterable, Identifiable {
    // Notes
    case noteCreated = "note.created"
    case noteUpdated = "note.updated"
    case noteDeleted = "note.deleted"

    // Mail
    case mailReceived = "mail.received"
    case mailSent = "mail.sent"

    // Tasks
    case taskCreated = "task.created"
    case taskCompleted = "task.completed"

    // GitHub
    case repoCommitPushed = "repo.commit.pushed"
    case repoPROpened = "repo.pr.opened"
    case repoPRMerged = "repo.pr.merged"

    // Meet
    case meetStarted = "meet.started"
    case meetTranscriptGenerated = "meet.transcript.generated"

    // Media
    case mediaImported = "media.imported"
    case mediaExported = "media.exported"

    // Calendar
    case calendarEventCreated = "calendar.event.created"
    case calendarEventUpdated = "calendar.event.updated"

    var id: String { rawValue }

    var capability: PluginCapability {
        if rawValue.starts(with: "note") { return .notes }
        if rawValue.starts(with: "mail") { return .mail }
        if rawValue.starts(with: "task") { return .tasks }
        if rawValue.starts(with: "repo") { return .github }
        if rawValue.starts(with: "meet") { return .meet }
        if rawValue.starts(with: "media") { return .media }
        if rawValue.starts(with: "calendar") { return .calendar }
        return .automation
    }
}

// MARK: - Permissions

enum PluginPermission: String, Codable, CaseIterable, Identifiable {
    case readNotes = "notes.read"
    case writeNotes = "notes.write"
    case readMail = "mail.read"
    case writeMail = "mail.write"
    case readTasks = "tasks.read"
    case writeTasks = "tasks.write"
    case readCalendar = "calendar.read"
    case writeCalendar = "calendar.write"
    case readFiles = "files.read"
    case writeFiles = "files.write"
    case aiGenerate = "ai.generate"
    case storageScoped = "storage.scoped"

    var id: String { rawValue }
}

struct PluginCommand: Codable, Identifiable {
    let id: UUID
    var keyword: String
    var description: String
    var parameters: [String]
}

// MARK: - Plugin Model

struct Plugin: Codable, Identifiable, Hashable {
    let id: UUID
    let identifier: String // com.ToolsKit.<name> - Immutable after creation
    var name: String
    var description: String
    var icon: String
    var version: String
    var author: String

    var capabilities: Set<PluginCapability>
    var actions: Set<PluginAction>
    var commands: [PluginCommand]
    var permissions: Set<PluginPermission>

    var sourceCode: String

    var isEnabled: Bool
    var isInstalled: Bool
    var isUserCreated: Bool

    var createdAt: Date
    var lastExecutedAt: Date?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Plugin, rhs: Plugin) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Runtime Models

struct PluginEvent: Codable, Identifiable {
    let id: UUID
    let type: PluginAction
    let capability: PluginCapability
    let payload: [String: String] // Simple string payload for now, can be expanded to [String: Any] with custom coding
    let timestamp: Date

    init(type: PluginAction, payload: [String: String]) {
        self.id = UUID()
        self.type = type
        self.capability = type.capability
        self.payload = payload
        self.timestamp = Date()
    }
}

struct PluginExecutionLog: Codable, Identifiable {
    let id: UUID
    let pluginID: UUID
    let eventID: UUID
    let timestamp: Date
    let output: String
    let status: ExecutionStatus

    enum ExecutionStatus: String, Codable {
        case success
        case failure
        case timeout
    }
}
