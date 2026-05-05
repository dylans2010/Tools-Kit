import Foundation

// MARK: - Plugin Definition

struct PluginDefinition: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var author: String
    var version: String
    var icon: String
    var identifier: String // com.ToolsKit.<userInput>
    var isEnabled: Bool = false
    var isInstalled: Bool = false
    var installedAt: Date? = nil
    var lastExecutedAt: Date? = nil
    var errorCount: Int = 0

    var capabilities: [PluginCapability]
    var actions: [PluginAction]
    var sourceCode: String

    var permissions: [PluginPermission] {
        capabilities.map { PluginPermission(capability: $0) }
    }
}

struct PluginPermission: Codable, Identifiable {
    var id: String { capability.rawValue }
    let capability: PluginCapability
    var description: String {
        switch capability {
        case .notes: return "Read, write, and delete notes."
        case .tasks: return "Manage tasks and completion status."
        case .mail: return "Access and send emails."
        case .calendar: return "Manage calendar events."
        case .files: return "Read and write to workspace files."
        case .whiteboard: return "Read and edit whiteboards."
        case .slides: return "Create and edit presentations."
        case .media: return "Import and edit media assets."
        case .meet: return "Start, join, and read meeting transcripts."
        case .github: return "Access repositories, commits, and PRs."
        case .automation: return "Create and execute workflows."
        case .intelligence: return "Access graph and semantic search."
        case .collaboration: return "Manage sessions and comments."
        case .ai: return "Generate, summarize, and classify with AI."
        }
    }
}

// MARK: - Capabilities & Actions

enum PluginCapability: String, Codable, CaseIterable, Identifiable {
    case notes, tasks, mail, calendar, files, whiteboard, slides, media, meet, github, automation, intelligence, collaboration, ai

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .notes: return "note.text"
        case .tasks: return "checkmark.circle"
        case .mail: return "envelope"
        case .calendar: return "calendar"
        case .files: return "doc"
        case .whiteboard: return "pencil.and.outline"
        case .slides: return "play.rectangle"
        case .media: return "photo.on.rectangle"
        case .meet: return "video"
        case .github: return "terminal"
        case .automation: return "gearshape.2"
        case .intelligence: return "brain"
        case .collaboration: return "person.2"
        case .ai: return "sparkles"
        }
    }
}

enum PluginAction: String, Codable, CaseIterable, Identifiable {
    // Notes
    case noteCreated = "note.created"
    case noteUpdated = "note.updated"
    case noteDeleted = "note.deleted"

    // Tasks
    case taskCreated = "task.created"
    case taskCompleted = "task.completed"
    case taskDeleted = "task.deleted"

    // Mail
    case mailReceived = "mail.received"
    case mailSent = "mail.sent"

    // GitHub
    case repoCommitPushed = "repo.commit.pushed"
    case repoPROpened = "repo.pr.opened"
    case repoPRMerged = "repo.pr.merged"

    // Meet
    case meetStarted = "meet.started"
    case meetEnded = "meet.ended"
    case meetTranscriptGenerated = "meet.transcript.generated"

    // Media
    case mediaImported = "media.imported"
    case mediaExported = "media.exported"

    // Calendar
    case calendarEventCreated = "calendar.event.created"
    case calendarEventUpdated = "calendar.event.updated"

    // Files
    case fileUploaded = "file.uploaded"
    case fileDeleted = "file.deleted"

    var id: String { rawValue }

    var parentCapability: PluginCapability {
        switch self {
        case .noteCreated, .noteUpdated, .noteDeleted: return .notes
        case .taskCreated, .taskCompleted, .taskDeleted: return .tasks
        case .mailReceived, .mailSent: return .mail
        case .repoCommitPushed, .repoPROpened, .repoPRMerged: return .github
        case .meetStarted, .meetEnded, .meetTranscriptGenerated: return .meet
        case .mediaImported, .mediaExported: return .media
        case .calendarEventCreated, .calendarEventUpdated: return .calendar
        case .fileUploaded, .fileDeleted: return .files
        }
    }
}

// MARK: - Event Models

struct PluginEvent: Codable, Identifiable {
    let id: UUID
    let capability: PluginCapability
    let action: String
    let payload: [String: String]
    let timestamp: Date
}
