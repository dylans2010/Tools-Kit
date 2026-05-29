import Foundation

public struct InstallEvent: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var timestamp: Date
    public var platform: String
    public var version: String

    public init(id: UUID = UUID(), appID: UUID, timestamp: Date = Date(), platform: String, version: String) {
        self.id = id
        self.appID = appID
        self.timestamp = timestamp
        self.platform = platform
        self.version = version
    }
}

public struct UninstallEvent: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var timestamp: Date

    public init(id: UUID = UUID(), appID: UUID, timestamp: Date = Date()) {
        self.id = id
        self.appID = appID
        self.timestamp = timestamp
    }
}

public struct CustomEventRecord: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var eventName: String
    public var payload: [String: String]
    public var timestamp: Date

    public init(id: UUID = UUID(), appID: UUID, eventName: String, payload: [String: String] = [:], timestamp: Date = Date()) {
        self.id = id
        self.appID = appID
        self.eventName = eventName
        self.payload = payload
        self.timestamp = timestamp
    }
}

public struct FunnelStep: Identifiable, Codable, Hashable {
    public var id: UUID
    public var order: Int
    public var eventName: String

    public init(id: UUID = UUID(), order: Int, eventName: String) {
        self.id = id
        self.order = order
        self.eventName = eventName
    }
}

public struct AnalyticsFunnel: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var steps: [FunnelStep]

    public init(id: UUID = UUID(), name: String, steps: [FunnelStep] = []) {
        self.id = id
        self.name = name
        self.steps = steps
    }
}

public struct DocumentationAnalyticsEvent: Identifiable, Codable, Hashable {
    public var id: UUID
    public var pageID: UUID
    public var timestamp: Date
    public var viewDuration: TimeInterval
    public var rating: Int? // 1-5

    public init(id: UUID = UUID(), pageID: UUID, timestamp: Date = Date(), viewDuration: TimeInterval = 0, rating: Int? = nil) {
        self.id = id
        self.pageID = pageID
        self.timestamp = timestamp
        self.viewDuration = viewDuration
        self.rating = rating
    }
}

public struct AccountActivityEvent: Identifiable, Codable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var eventType: String
    public var ipAddress: String
    public var deviceName: String

    public init(id: UUID = UUID(), timestamp: Date = Date(), eventType: String, ipAddress: String = "", deviceName: String = "") {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.ipAddress = ipAddress
        self.deviceName = deviceName
    }
}
