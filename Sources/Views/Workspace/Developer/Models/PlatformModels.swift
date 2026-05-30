import Foundation

/// DOMAIN E: DISTRIBUTION SYSTEM
public struct BuildDistribution: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var versionID: UUID
    public var platform: String
    public var distributionChannel: DistributionChannel
    public var status: DistributionStatus
    public var scheduledAt: Date?
    public var releasedAt: Date?

    public init(id: UUID = UUID(), appID: UUID, versionID: UUID, platform: String, channel: DistributionChannel, status: DistributionStatus = .pending) {
        self.id = id
        self.appID = appID
        self.versionID = versionID
        self.platform = platform
        self.distributionChannel = channel
        self.status = status
    }
}

public enum DistributionChannel: String, Codable, CaseIterable {
    case internalTest = "Internal"
    case beta = "Beta"
    case publicRelease = "Public"
}

public enum DistributionStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case processing = "Processing"
    case released = "Released"
    case rejected = "Rejected"
}

/// DOMAIN F: CONFIGURATION & ENVIRONMENTS
public struct FeatureFlag: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var key: String
    public var description: String
    public var isEnabled: Bool
    public var rolloutPercentage: Int // 0-100

    public init(id: UUID = UUID(), appID: UUID, key: String, description: String = "", isEnabled: Bool = false, rolloutPercentage: Int = 100) {
        self.id = id
        self.appID = appID
        self.key = key
        self.description = description
        self.isEnabled = isEnabled
        self.rolloutPercentage = rolloutPercentage
    }
}

/// DOMAIN G: DATA & STORAGE
public struct DatabaseEntity: Identifiable, Codable, Hashable {
    public var id: String { name }
    public var name: String
    public var recordCount: Int
    public var sizeInBytes: Int64
    public var lastModified: Date

    public init(name: String, recordCount: Int, sizeInBytes: Int64, lastModified: Date = Date()) {
        self.name = name
        self.recordCount = recordCount
        self.sizeInBytes = sizeInBytes
        self.lastModified = lastModified
    }
}

/// DOMAIN H: NETWORK & API STATE
public struct NetworkRequest: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var url: String
    public var method: String
    public var statusCode: Int?
    public var duration: TimeInterval
    public var timestamp: Date

    public init(id: UUID = UUID(), appID: UUID, url: String, method: String, statusCode: Int? = nil, duration: TimeInterval = 0, timestamp: Date = Date()) {
        self.id = id
        self.appID = appID
        self.url = url
        self.method = method
        self.statusCode = statusCode
        self.duration = duration
        self.timestamp = timestamp
    }
}

/// DOMAIN J: SYSTEM HEALTH
public struct SystemMetric: Identifiable, Codable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var cpuUsage: Double // 0.0 - 1.0
    public var memoryUsage: Int64 // Bytes
    public var diskUsage: Int64 // Bytes

    public init(id: UUID = UUID(), timestamp: Date = Date(), cpuUsage: Double, memoryUsage: Int64, diskUsage: Int64) {
        self.id = id
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
    }
}
