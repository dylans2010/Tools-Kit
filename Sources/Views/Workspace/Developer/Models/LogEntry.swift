import Foundation

public enum LogSeverity: String, Codable, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

public enum LogCategory: String, Codable, CaseIterable {
    case system = "System"
    case apiCall = "API Call"
    case authentication = "Authentication"
    case database = "Database"
    case networking = "Networking"
    case security = "Security"
    case application = "Application"
}

public struct LogSource: Codable, Hashable {
    public var component: String
    public var environment: String
    public var version: String

    public init(component: String, environment: String, version: String) {
        self.component = component
        self.environment = environment
        self.version = version
    }
}

public struct LogAlertRule: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var category: LogCategory
    public var severity: LogSeverity
    public var threshold: Int
    public var timeWindow: TimeInterval
    public var notificationMethod: String

    public init(id: UUID = UUID(), name: String, category: LogCategory, severity: LogSeverity, threshold: Int, timeWindow: TimeInterval, notificationMethod: String) {
        self.id = id
        self.name = name
        self.category = category
        self.severity = severity
        self.threshold = threshold
        self.timeWindow = timeWindow
        self.notificationMethod = notificationMethod
    }
}

public struct LogDrain: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var targetURL: String
    public var secretKeyID: UUID
    public var filterCategories: [LogCategory]

    public init(id: UUID = UUID(), name: String, targetURL: String, secretKeyID: UUID, filterCategories: [LogCategory] = []) {
        self.id = id
        self.name = name
        self.targetURL = targetURL
        self.secretKeyID = secretKeyID
        self.filterCategories = filterCategories
    }
}

public struct LogEntry: Identifiable, Codable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var severity: LogSeverity
    public var category: LogCategory
    public var source: LogSource
    public var message: String
    public var payload: String
    public var correlationID: String
    public var sessionID: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        severity: LogSeverity,
        category: LogCategory,
        source: LogSource,
        message: String,
        payload: String = "",
        correlationID: String = "",
        sessionID: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.severity = severity
        self.category = category
        self.source = source
        self.message = message
        self.payload = payload
        self.correlationID = correlationID
        self.sessionID = sessionID
    }
}
