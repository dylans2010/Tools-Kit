import Foundation
import Combine

public enum LogLevel: String, Codable, CaseIterable, Hashable {
    case debug
    case info
    case warning
    case error
}

public struct SDKLogEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let source: String?
    public init(id: UUID = UUID(), timestamp: Date = Date(),
                level: LogLevel, message: String, source: String? = nil) {
        self.id = id; self.timestamp = timestamp
        self.level = level; self.message = message; self.source = source
    }
}

public class SDKLogStore: ObservableObject {
    public static let shared = SDKLogStore()
    @Published public var entries: [SDKLogEntry] = []
    private init() {}
    public func log(_ message: String, source: String? = nil, level: LogLevel = .info) {
        let entry = SDKLogEntry(level: level, message: message, source: source)
        DispatchQueue.main.async { self.entries.append(entry) }
    }

    public func clear() {
        DispatchQueue.main.async { self.entries.removeAll() }
    }
}

public enum SDKScope: String, Codable, CaseIterable, Hashable {
    // Workspace access
    case workspaceRead
    case workspaceWrite
    // Feature scopes
    case persona
    case files
    case meet
    case emails
    case automations
    case notes
    case tasks
    case calendar
    case slides
    case repos
    case media
    case whiteboards
    case intelligence
    case plugins
    // SDK management
    case sdkManageFrameworks
    case sdkManageLibraries
    case sdkManagePackages
    case frameworkExecute
    case libraryInvoke
    // Data access
    case dataAccess
    case externalAPICall
    case read
    case write
    // Execution
    case execute
    case backgroundExecution
    case custom
    case sdkProjectCreate
    case agentExecute
    case agentTakeover
    // Wildcard
    case all

    public var displayName: String {
        switch self {
        case .workspaceRead: return "Workspace Read"
        case .workspaceWrite: return "Workspace Write"
        case .persona: return "Persona"
        case .files: return "Files"
        case .meet: return "Meet"
        case .emails: return "Emails"
        case .automations: return "Automations"
        case .notes: return "Notes"
        case .tasks: return "Tasks"
        case .calendar: return "Calendar"
        case .slides: return "Slides"
        case .repos: return "Repositories"
        case .media: return "Media"
        case .whiteboards: return "Whiteboards"
        case .intelligence: return "Intelligence"
        case .plugins: return "Plugins"
        case .sdkManageFrameworks: return "Manage Frameworks"
        case .sdkManageLibraries: return "Manage Libraries"
        case .sdkManagePackages: return "Manage Packages"
        case .frameworkExecute: return "Execute Framework"
        case .libraryInvoke: return "Invoke Library"
        case .dataAccess: return "Data Access"
        case .externalAPICall: return "External API Call"
        case .read: return "Read"
        case .write: return "Write"
        case .execute: return "Execute"
        case .backgroundExecution: return "Background Execution"
        case .custom: return "Custom"
        case .sdkProjectCreate: return "Create SDK Project"
        case .agentExecute: return "Agent Execution"
        case .agentTakeover: return "Agent Takeover"
        case .all: return "All"
        }
    }
}
