import Foundation
import Combine

public struct SDKDataItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var key: String
    public var value: String
    public var scope: SDKScope
    public var title: String { key }
    public var timestamp: Date
    public var codablePayload: [String: String] = [:]

    public init(id: UUID = UUID(), key: String, value: String,
                scope: SDKScope = .dataAccess, timestamp: Date = Date(),
                payload: [String: String] = [:]) {
        self.id = id; self.key = key; self.value = value; self.scope = scope
        self.timestamp = timestamp; self.codablePayload = payload
    }

    public init(id: UUID = UUID(), scope: SDKScope, title: String,
                payload: [String: String], timestamp: Date) {
        self.id = id; self.key = title; self.value = ""; self.scope = scope
        self.timestamp = timestamp; self.codablePayload = payload
    }
}

public struct SDKQuery: Codable, Hashable {
    public var scope: SDKScope
    public var predicate: String?
    public var filters: [SDKFilter] = []
    public var pagination: SDKPagination?

    public init(scope: SDKScope, predicate: String? = nil, filters: [SDKFilter] = [], pagination: SDKPagination? = nil) {
        self.scope = scope; self.predicate = predicate; self.filters = filters; self.pagination = pagination
    }

    public struct SDKPagination: Codable, Hashable {
        public var page: Int
        public var pageSize: Int
        public init(page: Int, pageSize: Int) {
            self.page = page; self.pageSize = pageSize
        }
    }
}

public struct SDKFilter: Codable, Hashable {
    public var key: String?
    public var scope: SDKScope?
    public var type: FilterType

    public enum FilterType: Codable, Hashable {
        case date(from: Date?, to: Date?)
        case tags([String])
        case ownership(String)
        case type(String)
        case keyword(String)
    }

    public init(key: String? = nil, scope: SDKScope? = nil, type: FilterType = .keyword("")) {
        self.key = key; self.scope = scope; self.type = type
    }
}

public enum SDKWriteResult: Codable, Hashable {
    case success
    case failure(String)
}

public struct SDKCacheInfo: Codable, Hashable {
    public var key: String
    public var expiresAt: Date?
    public var scope: SDKScope
    public var itemCount: Int
    public var lastRefreshed: Date?
    public var isValid: Bool
    public var ttlRemaining: TimeInterval

    public init(key: String, expiresAt: Date? = nil, scope: SDKScope = .all,
                itemCount: Int = 0, lastRefreshed: Date? = nil,
                isValid: Bool = false, ttlRemaining: TimeInterval = 0) {
        self.key = key; self.expiresAt = expiresAt; self.scope = scope
        self.itemCount = itemCount; self.lastRefreshed = lastRefreshed
        self.isValid = isValid; self.ttlRemaining = ttlRemaining
    }

    public init(scope: SDKScope, itemCount: Int, lastRefreshed: Date?, isValid: Bool, ttlRemaining: TimeInterval) {
        self.key = scope.rawValue
        self.expiresAt = lastRefreshed?.addingTimeInterval(ttlRemaining)
        self.scope = scope
        self.itemCount = itemCount
        self.lastRefreshed = lastRefreshed
        self.isValid = isValid
        self.ttlRemaining = ttlRemaining
    }
}

extension SDKScope {
    var cacheKey: String { rawValue }
}

@MainActor
public final class SDKDataEngine: ObservableObject {
    public static let shared = SDKDataEngine()

    @Published public private(set) var isInitialized = false

    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheTTL: TimeInterval = 300
    private var cacheTimestamps: [String: Date] = [:]
    private let batchQueue = DispatchQueue(label: "com.toolskit.sdk.data.batch", attributes: .concurrent)

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        isInitialized = true
    }

    private class CacheEntry {
        let items: [SDKDataItem]
        let timestamp: Date
        init(items: [SDKDataItem], timestamp: Date) {
            self.items = items
            self.timestamp = timestamp
        }
    }

    // MARK: - Fetch

    public func fetch(scope: SDKScope) async throws -> [SDKDataItem] {
        if let cached = getCachedItems(for: scope) {
            return cached
        }

        let items = try await fetchFromWorkspace(scope: scope)
        setCachedItems(items, for: scope)
        return items
    }

    public func fetch(query: SDKQuery) async throws -> [SDKDataItem] {
        var items = try await fetch(scope: query.scope)

        for filter in query.filters {
            items = applyFilter(filter, to: items)
        }

        if let pagination = query.pagination {
            let start = (pagination.page - 1) * pagination.pageSize
            let end = min(start + pagination.pageSize, items.count)
            guard start < items.count else { return [] }
            items = Array(items[start..<end])
        }

        return items
    }

    // MARK: - Write

    public func write(scope: SDKScope, title: String, payload: [String: Any]) async throws -> SDKWriteResult {
        let id = UUID()

        switch scope {
        case .notes:
            _ = WorkspaceAPI.shared.notes.createNote(title: title, content: payload["content"] as? String ?? "")
        case .tasks:
            let dueDate = payload["dueDate"] as? Date
            _ = WorkspaceAPI.shared.tasks.createTask(title: title, dueDate: dueDate)
        case .calendar:
            let start = payload["start"] as? Date ?? Date()
            let end = payload["end"] as? Date ?? Date().addingTimeInterval(3600)
            WorkspaceAPI.shared.calendar.createEvent(title: title, start: start, end: end)
        case .slides:
            WorkspaceAPI.shared.slides.createDeck(title: title)
        case .emails:
            let to = payload["to"] as? String ?? ""
            let body = payload["body"] as? String ?? ""
            try await WorkspaceAPI.shared.mail.sendMail(to: to, subject: title, body: body)
        default:
            break
        }

        invalidateCache(scope: scope)
        SDKLogStore.shared.log("writeData scope=\(scope) title=\(title)", source: "SDKDataEngine", level: .info)
        return .success
    }

    // MARK: - Delete

    public func delete(scope: SDKScope, id: UUID) async throws {
        switch scope {
        case .files:
            WorkspaceAPI.shared.files.deleteFile(id: id.uuidString)
        default:
            break
        }

        invalidateCache(scope: scope)
        SDKLogStore.shared.log("deleteData scope=\(scope) id=\(id)", source: "SDKDataEngine", level: LogLevel.info)
    }

    // MARK: - Cache Management

    public func cacheInfo(for scope: SDKScope) -> SDKCacheInfo {
        let key = scope.cacheKey
        if let entry = cache.object(forKey: key as NSString) {
            let elapsed = Date().timeIntervalSince(entry.timestamp)
            let remaining = max(0, cacheTTL - elapsed)
            return SDKCacheInfo(
                scope: scope,
                itemCount: entry.items.count,
                lastRefreshed: entry.timestamp,
                isValid: remaining > 0,
                ttlRemaining: remaining
            )
        }
        return SDKCacheInfo(scope: scope, itemCount: 0, lastRefreshed: nil, isValid: false, ttlRemaining: 0)
    }

    public func invalidateCache(scope: SDKScope? = nil) {
        if let scope = scope {
            cache.removeObject(forKey: scope.cacheKey as NSString)
            cacheTimestamps.removeValue(forKey: scope.cacheKey)
        } else {
            cache.removeAllObjects()
            cacheTimestamps.removeAll()
        }
    }

    public func cacheSnapshot() -> [SDKScope: Int] {
        var snapshot: [SDKScope: Int] = [:]
        for scope in SDKScope.allCases {
            if let items = getCachedItems(for: scope) {
                snapshot[scope] = items.count
            } else {
                snapshot[scope] = 0
            }
        }
        return snapshot
    }

    // MARK: - Private

    private func getCachedItems(for scope: SDKScope) -> [SDKDataItem]? {
        guard let entry = cache.object(forKey: scope.cacheKey as NSString),
              Date().timeIntervalSince(entry.timestamp) < cacheTTL else {
            return nil
        }
        return entry.items
    }

    private func setCachedItems(_ items: [SDKDataItem], for scope: SDKScope) {
        let entry = CacheEntry(items: items, timestamp: Date())
        cache.setObject(entry, forKey: scope.cacheKey as NSString)
        cacheTimestamps[scope.cacheKey] = Date()
    }

    private func fetchFromWorkspace(scope: SDKScope) async throws -> [SDKDataItem] {
        switch scope {
        case .tasks:
            return WorkspaceAPI.shared.tasks.listTasks().map { task in
                SDKDataItem(id: task.id, scope: .tasks, title: task.title,
                           payload: ["completed": "\(task.completed)", "description": task.description],
                           timestamp: task.createdAt)
            }
        case .notes:
            return WorkspaceAPI.shared.notes.listNotes().map { note in
                SDKDataItem(id: note.id, scope: .notes, title: note.title,
                           payload: ["content": note.content],
                           timestamp: note.updatedAt)
            }
        case .calendar:
            return WorkspaceAPI.shared.calendar.listEvents().map { event in
                SDKDataItem(id: event.id, scope: .calendar, title: event.title,
                           payload: ["location": event.location],
                           timestamp: event.date)
            }
        case .files:
            return WorkspaceAPI.shared.files.listFiles().map { file in
                SDKDataItem(id: UUID(), scope: .files, title: file.name,
                           payload: ["path": file.url.path],
                           timestamp: Date())
            }
        case .emails:
            return WorkspaceAPI.shared.mail.listMessages().map { mail in
                SDKDataItem(id: UUID(), scope: .emails, title: mail.subject,
                           payload: ["from": mail.from, "to": mail.to.joined(separator: ", ")],
                           timestamp: mail.date)
            }
        case .slides:
            return WorkspaceAPI.shared.slides.listDecks().map { deck in
                SDKDataItem(id: deck.id, scope: .slides, title: deck.title,
                           payload: ["slideCount": "\(deck.slides.count)"],
                           timestamp: deck.updatedAt)
            }
        case .automations:
            return SDKAutomationEngine.shared.rules.map { rule in
                SDKDataItem(id: rule.id, scope: .automations, title: rule.name,
                           payload: ["enabled": "\(rule.isEnabled)", "runCount": "\(rule.runCount)"],
                           timestamp: rule.lastRunAt ?? Date())
            }
        case .meet:
            let snapshots = WorkspaceAPI.shared.timeTravel.listSnapshots()
            let meetSnapshots = snapshots.filter { $0.message.lowercased().contains("meet") }
            return meetSnapshots.map { snapshot in
                SDKDataItem(id: snapshot.id, scope: .meet, title: snapshot.message,
                           payload: ["timestamp": "\(snapshot.timestamp)"],
                           timestamp: snapshot.timestamp)
            }
        case .repos:
            let files = WorkspaceAPI.shared.files.listFiles()
            let repoFiles = files.filter { $0.name.hasSuffix(".git") || $0.url.path.contains(".git") || $0.name.hasSuffix(".swift") || $0.name.hasSuffix(".json") }
            return repoFiles.map { file in
                SDKDataItem(id: UUID(), scope: .repos, title: file.name,
                           payload: ["path": file.url.path],
                           timestamp: Date())
            }
        case .media:
            let files = WorkspaceAPI.shared.files.listFiles()
            let mediaExtensions = ["png", "jpg", "jpeg", "gif", "mp4", "mov", "mp3", "wav", "pdf"]
            let mediaFiles = files.filter { file in
                mediaExtensions.contains(where: { file.name.lowercased().hasSuffix(".\($0)") })
            }
            return mediaFiles.map { file in
                SDKDataItem(id: UUID(), scope: .media, title: file.name,
                           payload: ["path": file.url.path],
                           timestamp: Date())
            }
        case .whiteboards:
            let notes = WorkspaceAPI.shared.notes.listNotes()
            let whiteboardNotes = notes.filter { $0.title.lowercased().contains("whiteboard") || $0.content.lowercased().contains("canvas") }
            return whiteboardNotes.map { note in
                SDKDataItem(id: note.id, scope: .whiteboards, title: note.title,
                           payload: ["content": note.content],
                           timestamp: note.updatedAt)
            }
        case .intelligence:
            let graph = SDKGraphInterface.shared.query(entityType: nil, relation: nil)
            return graph.nodes.map { node in
                SDKDataItem(id: node.id, scope: .intelligence, title: node.label,
                           payload: ["type": node.type],
                           timestamp: Date())
            }
        case .persona:
            let insights = WorkspaceAPI.shared.persona.getInsights()
            return insights.enumerated().map { index, insight in
                SDKDataItem(id: UUID(), scope: .persona, title: "Insight \(index + 1)",
                           payload: ["content": insight],
                           timestamp: Date())
            }
        case .plugins:
            return SDKPluginManager.shared.plugins.map { plugin in
                SDKDataItem(id: plugin.id, scope: .plugins, title: plugin.name,
                           payload: ["version": plugin.version, "enabled": "\(plugin.isEnabled)"],
                           timestamp: plugin.installedAt)
            }
        case .all:
            var allItems: [SDKDataItem] = []
            for childScope in SDKScope.allCases where childScope != .all {
                if let items = try? await fetchFromWorkspace(scope: childScope) {
                    allItems.append(contentsOf: items)
                }
            }
            return allItems.sorted { $0.timestamp > $1.timestamp }
        case .custom,
             .workspaceRead,
             .workspaceWrite,
             .dataAccess,
             .externalAPICall,
             .read,
             .write,
             .execute,
             .backgroundExecution,
             .sdkProjectCreate,
             .sdkManageLibraries,
             .sdkManageFrameworks,
             .sdkManagePackages,
             .frameworkExecute,
             .libraryInvoke,
             .agentExecute,
             .agentTakeover:
            return []
        }
    }

    private func searchWorkspace(query: String) async throws -> [SDKDataItem] {
        let lowered = query.lowercased()
        var results: [SDKDataItem] = []

        for scope in SDKScope.allCases where scope != .all {
            if let items = try? await fetchFromWorkspace(scope: scope) {
                results.append(contentsOf: items.filter {
                    $0.title.lowercased().contains(lowered)
                })
            }
        }

        return results
    }

    private func applyFilter(_ filter: SDKFilter, to items: [SDKDataItem]) -> [SDKDataItem] {
        switch filter.type {
        case .date(let from, let to):
            return items.filter { item in
                if let from = from, item.timestamp < from { return false }
                if let to = to, item.timestamp > to { return false }
                return true
            }
        case .tags(let tags):
            return items.filter { item in
                let itemTags = item.codablePayload["tags"]?.components(separatedBy: ",") ?? []
                return !Set(tags).isDisjoint(with: Set(itemTags))
            }
        case .ownership(let owner):
            return items.filter { $0.codablePayload["owner"] == owner }
        case .type(let type):
            return items.filter { "\($0.scope)" == type }
        case .keyword(let keyword):
            let lowered = keyword.lowercased()
            return items.filter {
                $0.title.lowercased().contains(lowered) ||
                $0.codablePayload.values.contains { $0.lowercased().contains(lowered) }
            }
        }
    }
}
