import Foundation

public enum SDKDataType: String, Codable, CaseIterable {
    case notes
    case tasks
    case mail
    case calendar
    case files
    case whiteboards
    case slides
    case media
    case meet
    case github
    case automation
    case intelligence
    case collaboration
    case persona
    case timeTravelSnapshots
}

public enum SDKFetchMode: String, Codable {
    case full
    case partial
    case stream
    case snapshot
    case diff
    case query
    case graph
}

public struct SDKDataFilter: Codable {
    public var query: String?
    public var startDate: Date?
    public var endDate: Date?
    public var tags: [String]?
    public var status: String?
    public var authorID: String?
    public var customFilters: [String: String]?

    public init(query: String? = nil, startDate: Date? = nil, endDate: Date? = nil, tags: [String]? = nil, status: String? = nil, authorID: String? = nil, customFilters: [String: String]? = nil) {
        self.query = query
        self.startDate = startDate
        self.endDate = endDate
        self.tags = tags
        self.status = status
        self.authorID = authorID
        self.customFilters = customFilters
    }
}

public struct SDKFetchRequest: Codable {
    public var dataTypes: [SDKDataType]
    public var filters: SDKDataFilter
    public var mode: SDKFetchMode
    public var scopes: [PluginCapability]
    public var includeRelations: Bool
    public var includeMetadata: Bool
    public var includeHistory: Bool
    public var includeDiff: Bool
    public var realtime: Bool
    public var limit: Int
    public var offset: Int

    public init(dataTypes: [SDKDataType], filters: SDKDataFilter = SDKDataFilter(), mode: SDKFetchMode = .full, scopes: [PluginCapability] = [], includeRelations: Bool = false, includeMetadata: Bool = true, includeHistory: Bool = false, includeDiff: Bool = false, realtime: Bool = false, limit: Int = 50, offset: Int = 0) {
        self.dataTypes = dataTypes
        self.filters = filters
        self.mode = mode
        self.scopes = scopes
        self.includeRelations = includeRelations
        self.includeMetadata = includeMetadata
        self.includeHistory = includeHistory
        self.includeDiff = includeDiff
        self.realtime = realtime
        self.limit = limit
        self.offset = offset
    }
}

public struct SDKDataNode: Identifiable, Codable {
    public let id: String
    public let type: SDKDataType
    public let title: String
    public let content: String
    public let metadata: [String: String]
    public let createdAt: Date
    public let updatedAt: Date
    public var relations: [SDKRelation]

    public init(id: String, type: SDKDataType, title: String, content: String, metadata: [String: String] = [:], createdAt: Date = Date(), updatedAt: Date = Date(), relations: [SDKRelation] = []) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.relations = relations
    }
}

public struct SDKRelation: Codable {
    public let sourceID: String
    public let targetID: String
    public let type: String // e.g., "mentions", "assigned_to", "references"
    public let metadata: [String: String]

    public init(sourceID: String, targetID: String, type: String, metadata: [String: String] = [:]) {
        self.sourceID = sourceID
        self.targetID = targetID
        self.type = type
        self.metadata = metadata
    }
}

public struct SDKMetadata: Codable {
    public let totalCount: Int
    public let resultCount: Int
    public let sourceSystems: [String]
    public let permissionsGranted: [PluginCapability]

    public init(totalCount: Int, resultCount: Int, sourceSystems: [String], permissionsGranted: [PluginCapability]) {
        self.totalCount = totalCount
        self.resultCount = resultCount
        self.sourceSystems = sourceSystems
        self.permissionsGranted = permissionsGranted
    }
}

public struct SDKTimelineEvent: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let eventType: String
    public let description: String
    public let dataNodeID: String?

    public init(id: UUID = UUID(), timestamp: Date = Date(), eventType: String, description: String, dataNodeID: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.description = description
        self.dataNodeID = dataNodeID
    }
}

public struct SDKDiffResult: Codable {
    public var added: [SDKDataNode]
    public var removed: [SDKDataNode]
    public var modified: [SDKDataNode]

    public init(added: [SDKDataNode] = [], removed: [SDKDataNode] = [], modified: [SDKDataNode] = []) {
        self.added = added
        self.removed = removed
        self.modified = modified
    }
}

public struct SDKPerformanceMetrics: Codable {
    public let fetchTime: TimeInterval
    public let processingTime: TimeInterval
    public let cacheHit: Bool
    public let parallelExecution: Bool

    public init(fetchTime: TimeInterval, processingTime: TimeInterval, cacheHit: Bool, parallelExecution: Bool) {
        self.fetchTime = fetchTime
        self.processingTime = processingTime
        self.cacheHit = cacheHit
        self.parallelExecution = parallelExecution
    }
}

public struct SDKFetchResult: Codable {
    public let data: [SDKDataNode]
    public let relations: [SDKRelation]
    public let metadata: SDKMetadata
    public let timeline: [SDKTimelineEvent]
    public let diff: SDKDiffResult?
    public let performance: SDKPerformanceMetrics

    public init(data: [SDKDataNode], relations: [SDKRelation] = [], metadata: SDKMetadata, timeline: [SDKTimelineEvent] = [], diff: SDKDiffResult? = nil, performance: SDKPerformanceMetrics) {
        self.data = data
        self.relations = relations
        self.metadata = metadata
        self.timeline = timeline
        self.diff = diff
        self.performance = performance
    }
}
