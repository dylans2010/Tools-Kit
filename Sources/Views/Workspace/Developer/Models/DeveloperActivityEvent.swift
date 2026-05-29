import Foundation

public enum DeveloperActivityEventType: String, Codable, CaseIterable {
    case appCreated = "App Created"
    case appUpdated = "App Updated"
    case appDeleted = "App Deleted"
    case keyGenerated = "Key Generated"
    case keyRevoked = "Key Revoked"
    case keyRotated = "Key Rotated"
    case scopeRequested = "Scope Requested"
    case scopeGranted = "Scope Granted"
    case submissionStarted = "Submission Started"
    case submissionCompleted = "Submission Completed"
}

public struct DeveloperActivityEvent: Identifiable, Codable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var eventType: DeveloperActivityEventType
    public var sourceAppID: UUID?
    public var sourceAppName: String?
    public var relatedRecordID: UUID?

    public var description: String {
        switch eventType {
        case .appCreated:
            return "New project '\(sourceAppName ?? "Unknown")' was added."
        case .appUpdated:
            return "Project '\(sourceAppName ?? "Unknown")' was updated."
        case .appDeleted:
            return "Project '\(sourceAppName ?? "Unknown")' was deleted."
        case .keyGenerated:
            return "A new API key was generated."
        case .keyRevoked:
            return "An API key was revoked."
        case .keyRotated:
            return "An API key was rotated."
        case .scopeRequested:
            return "A new permission scope was requested."
        case .scopeGranted:
            return "A permission scope was granted."
        case .submissionStarted:
            return "Marketplace submission draft created for '\(sourceAppName ?? "Unknown")'."
        case .submissionCompleted:
            return "Project '\(sourceAppName ?? "Unknown")' submitted to Marketplace."
        }
    }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        eventType: DeveloperActivityEventType,
        sourceAppID: UUID? = nil,
        sourceAppName: String? = nil,
        relatedRecordID: UUID? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.sourceAppID = sourceAppID
        self.sourceAppName = sourceAppName
        self.relatedRecordID = relatedRecordID
    }
}
