import Foundation

public struct DeveloperPlugin: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var description: String
    public var developerID: UUID
    public var status: PluginStatus
    public var version: String
    public var category: String
    public var icon: String

    public enum PluginStatus: String, Codable {
        case draft, inReview, published, rejected, disabled
    }

    public init(id: UUID = UUID(), name: String, description: String, developerID: UUID, status: PluginStatus = .draft, version: String = "1.0.0", category: String = "Utility", icon: String = "puzzlepiece") {
        self.id = id
        self.name = name
        self.description = description
        self.developerID = developerID
        self.status = status
        self.version = version
        self.category = category
        self.icon = icon
    }
}

public struct PluginAnalytics: Identifiable, Codable, Hashable {
    public var id: UUID
    public var pluginID: UUID
    public var installsCount: Int
    public var activeUsers: Int
    public var crashCount: Int
    public var averageLatency: TimeInterval

    public init(id: UUID = UUID(), pluginID: UUID, installsCount: Int = 0, activeUsers: Int = 0, crashCount: Int = 0, averageLatency: TimeInterval = 0) {
        self.id = id
        self.pluginID = pluginID
        self.installsCount = installsCount
        self.activeUsers = activeUsers
        self.crashCount = crashCount
        self.averageLatency = averageLatency
    }
}

public struct ConnectorConfig: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var type: String // e.g., "REST", "GraphQL", "gRPC"
    public var baseURL: String
    public var authType: String // "Bearer", "APIKey", "None"
    public var isEnabled: Bool

    public init(id: UUID = UUID(), name: String, type: String, baseURL: String, authType: String = "None", isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.type = type
        self.baseURL = baseURL
        self.authType = authType
        self.isEnabled = isEnabled
    }
}

public struct ConnectorHealth: Identifiable, Codable, Hashable {
    public var id: UUID
    public var connectorID: UUID
    public var status: HealthStatus
    public var uptimePercentage: Double
    public var lastCheck: Date
    public var errorCount: Int

    public enum HealthStatus: String, Codable {
        case healthy, degraded, down, unknown
    }

    public init(id: UUID = UUID(), connectorID: UUID, status: HealthStatus = .healthy, uptimePercentage: Double = 100.0, lastCheck: Date = Date(), errorCount: Int = 0) {
        self.id = id
        self.connectorID = connectorID
        self.status = status
        self.uptimePercentage = uptimePercentage
        self.lastCheck = lastCheck
        self.errorCount = errorCount
    }
}

public struct DeveloperBounty: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var description: String
    public var rewardAmount: Double
    public var currency: String
    public var status: BountyStatus
    public var createdAt: Date

    public enum BountyStatus: String, Codable {
        case open, inProgress, underReview, completed, cancelled
    }

    public init(id: UUID = UUID(), title: String, description: String, rewardAmount: Double, currency: String = "USD", status: BountyStatus = .open, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.rewardAmount = rewardAmount
        self.currency = currency
        self.status = status
        self.createdAt = createdAt
    }
}

public struct APIRateLimit: Identifiable, Codable, Hashable {
    public var id: UUID
    public var endpoint: String
    public var limit: Int
    public var windowSeconds: Int
    public var isEnabled: Bool

    public init(id: UUID = UUID(), endpoint: String, limit: Int, windowSeconds: Int = 60, isEnabled: Bool = true) {
        self.id = id
        self.endpoint = endpoint
        self.limit = limit
        self.windowSeconds = windowSeconds
        self.isEnabled = isEnabled
    }
}

public struct TrafficPacket: Identifiable, Codable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var method: String
    public var path: String
    public var statusCode: Int
    public var duration: Double

    public init(id: UUID = UUID(), timestamp: Date = Date(), method: String, path: String, statusCode: Int, duration: Double) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
        self.path = path
        self.statusCode = statusCode
        self.duration = duration
    }
}

public struct AuthProfile: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var type: String
    public var identifier: String

    public init(id: UUID = UUID(), name: String, type: String, identifier: String) {
        self.id = id
        self.name = name
        self.type = type
        self.identifier = identifier
    }
}

public struct LogicScript: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var lastModified: Date
    public var size: String

    public init(id: UUID = UUID(), name: String, lastModified: Date = Date(), size: String) {
        self.id = id
        self.name = name
        self.lastModified = lastModified
        self.size = size
    }
}
