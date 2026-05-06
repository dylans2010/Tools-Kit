import Foundation
import Combine

public struct SDKDataItem: Identifiable {
    public let id: UUID
    public let scope: SDKScope
    public let title: String
    public let payload: [String: Any]
    public let timestamp: Date
}

public enum SDKScope: Hashable, CaseIterable, Codable {
    case all, tasks, notes, calendar, files, emails, whiteboards, plugins
    case custom(query: String)

    public static var allCases: [SDKScope] {
        return [.all, .tasks, .notes, .calendar, .files, .emails, .whiteboards, .plugins]
    }

    private enum CodingKeys: String, CodingKey {
        case type, query
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "all": self = .all
        case "tasks": self = .tasks
        case "notes": self = .notes
        case "calendar": self = .calendar
        case "files": self = .files
        case "emails": self = .emails
        case "whiteboards": self = .whiteboards
        case "plugins": self = .plugins
        case "custom":
            let query = try container.decode(String.self, forKey: .query)
            self = .custom(query: query)
        default:
            self = .all
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .all: try container.encode("all", forKey: .type)
        case .tasks: try container.encode("tasks", forKey: .type)
        case .notes: try container.encode("notes", forKey: .type)
        case .calendar: try container.encode("calendar", forKey: .type)
        case .files: try container.encode("files", forKey: .type)
        case .emails: try container.encode("emails", forKey: .type)
        case .whiteboards: try container.encode("whiteboards", forKey: .type)
        case .plugins: try container.encode("plugins", forKey: .type)
        case .custom(let query):
            try container.encode("custom", forKey: .type)
            try container.encode(query, forKey: .query)
        }
    }

    var cacheKey: String {
        switch self {
        case .custom(let query): return "custom_\(query)"
        default: return String(describing: self)
        }
    }
}

@MainActor
public final class ToolsKitSDK: ObservableObject {
    public static let shared = ToolsKitSDK()

    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheTTL: TimeInterval = 300 // 5 minutes

    @Published public var isSyncing = false

    private init() {}

    private class CacheEntry {
        let items: [SDKDataItem]
        let timestamp: Date
        init(items: [SDKDataItem], timestamp: Date) {
            self.items = items
            self.timestamp = timestamp
        }
    }

    /// Fetches data from the Workspace OS based on the provided scope.
    /// Supports multi-source joins, pagination, and real-time data access.
    public func fetchData(scope: SDKScope, limit: Int = 100, offset: Int = 0) async throws -> [SDKDataItem] {
        if let cached = cache.object(forKey: scope.cacheKey as NSString),
           Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.items
        }

        let items = try await fetchFromSource(scope: scope)
        let normalized = normalize(items, for: scope)

        // Handle pagination
        let pagedItems = Array(normalized.dropFirst(offset).prefix(limit))

        cache.setObject(CacheEntry(items: pagedItems, timestamp: Date()), forKey: scope.cacheKey as NSString)
        return pagedItems
    }

    private func fetchFromSource(scope: SDKScope) async throws -> [Any] {
        switch scope {
        case .tasks:
            return WorkspaceAPI.shared.tasks.listTasks()
        case .notes:
            return WorkspaceAPI.shared.notes.listNotes()
        case .calendar:
            return WorkspaceAPI.shared.calendar.listEvents()
        case .files:
            return WorkspaceAPI.shared.files.listFiles()
        case .emails:
            return WorkspaceAPI.shared.mail.listMessages()
        case .whiteboards:
            return WorkspaceAPI.shared.spatial.listWhiteboards()
        case .plugins:
            return SDKPluginManager.shared.plugins
        case .all:
            return try await joinAllData()
        case .custom(let query):
            return try await performGraphQuery(query)
        }
    }

    private func joinAllData() async throws -> [Any] {
        async let tasks = WorkspaceAPI.shared.tasks.listTasks()
        async let notes = WorkspaceAPI.shared.notes.listNotes()
        async let events = WorkspaceAPI.shared.calendar.listEvents()
        return (await tasks as [Any]) + (await notes as [Any]) + (await events as [Any])
    }

    private func performGraphQuery(_ query: String) async throws -> [Any] {
        // Real-world graph traversal via Intelligence API
        let graph = WorkspaceAPI.shared.intelligence.getGraph()
        // Simple filter based on query for now, but using real graph structure
        return graph.filter { ($0.value as? String)?.contains(query) ?? false }.map { $0.value }
    }

    private func normalize(_ items: [Any], for scope: SDKScope) -> [SDKDataItem] {
        return items.compactMap { item in
            if let task = item as? WorkspaceTask {
                return SDKDataItem(id: task.id, scope: .tasks, title: task.title, payload: ["completed": task.completed, "priority": task.priority.rawValue], timestamp: task.createdAt)
            } else if let note = item as? Note {
                return SDKDataItem(id: note.id, scope: .notes, title: note.title, payload: ["content": note.content], timestamp: note.updatedAt)
            } else if let event = item as? CalendarEvent {
                return SDKDataItem(id: event.id, scope: .calendar, title: event.title, payload: ["location": event.location, "start": event.startTime], timestamp: event.date)
            } else if let file = item as? ManagedFileItem {
                return SDKDataItem(id: UUID(), scope: .files, title: file.name, payload: ["path": file.path, "size": file.size], timestamp: Date())
            } else if let mail = item as? MailMessage {
                return SDKDataItem(id: UUID(), scope: .emails, title: mail.subject, payload: ["from": mail.from, "threadId": mail.threadId], timestamp: mail.date)
            } else if let canvas = item as? SpatialCanvas {
                return SDKDataItem(id: canvas.id, scope: .whiteboards, title: canvas.name, payload: ["layerCount": canvas.layers.count], timestamp: Date())
            } else if let plugin = item as? SDKPlugin {
                return SDKDataItem(id: plugin.id, scope: .plugins, title: plugin.name, payload: ["version": plugin.version, "author": plugin.author], timestamp: Date())
            }
            return nil
        }
    }

    // MARK: - SDK Methods

    public func registerPlugin(_ plugin: SDKPlugin) throws {
        try SDKPluginManager.shared.install(plugin)
    }

    public func executeTool(toolID: UUID) async throws -> SDKToolResult {
        return try await SDKToolManager.shared.execute(toolID: toolID, input: [:])
    }

    public func runAutomation(_ rule: SDKAutomationRule) async throws {
        SDKAutomationEngine.shared.add(rule)
    }

    public func syncConnectors() async throws {
        isSyncing = true
        defer { isSyncing = false }
        try await SDKConnectorManager.shared.syncAll()
    }
}

public struct Note: Identifiable {
    public let id: UUID
    public let title: String
    public let content: String
    public let createdAt: Date
    public let updatedAt: Date
}
