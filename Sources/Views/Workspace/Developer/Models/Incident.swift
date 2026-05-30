import Foundation

public enum IncidentSeverity: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

public enum IncidentStatus: String, Codable, CaseIterable {
    case investigating = "Investigating"
    case identified = "Identified"
    case monitoring = "Monitoring"
    case resolved = "Resolved"
}

public struct Incident: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var title: String
    public var description: String
    public var severity: IncidentSeverity
    public var status: IncidentStatus
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        appID: UUID,
        title: String,
        description: String = "",
        severity: IncidentSeverity = .medium,
        status: IncidentStatus = .investigating,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.appID = appID
        self.title = title
        self.description = description
        self.severity = severity
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
