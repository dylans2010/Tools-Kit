import Foundation

public enum ScopeCategory: String, Codable, CaseIterable {
    case identity = "Identity"
    case workspace = "Workspace"
    case automation = "Automation"
    case system = "System"
}

public enum ScopeRiskLevel: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

public struct DeveloperScope: Identifiable, Codable, Hashable {
    public var id: String // e.g. "read:user"
    public var name: String
    public var description: String
    public var riskLevel: ScopeRiskLevel
    public var category: ScopeCategory
    public var requiredTier: DeveloperTier
    public var isDeprecated: Bool

    public init(id: String, name: String, description: String, riskLevel: ScopeRiskLevel, category: ScopeCategory, requiredTier: DeveloperTier = .community, isDeprecated: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.riskLevel = riskLevel
        self.category = category
        self.requiredTier = requiredTier
        self.isDeprecated = isDeprecated
    }
}

public struct GrantedScope: Identifiable, Codable, Hashable {
    public var id: UUID
    public var scopeIdentifier: String
    public var appID: UUID?
    public var grantDate: Date
    public var expiresAt: Date?

    public init(id: UUID = UUID(), scopeIdentifier: String, appID: UUID? = nil, grantDate: Date = Date(), expiresAt: Date? = nil) {
        self.id = id
        self.scopeIdentifier = scopeIdentifier
        self.appID = appID
        self.grantDate = grantDate
        self.expiresAt = expiresAt
    }
}

public struct ScopeRequest: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appId: UUID
    public var scopeIdentifier: String
    public var justification: String
    public var useCaseDescription: String
    public var expectedVolume: String
    public var policyURL: String
    public var status: RequestStatus
    public var requestedAt: Date

    public enum RequestStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case cancelled = "Cancelled"
    }

    public init(
        id: UUID = UUID(),
        appId: UUID,
        scopeIdentifier: String,
        justification: String,
        useCaseDescription: String = "",
        expectedVolume: String = "",
        policyURL: String = "",
        status: RequestStatus = .pending,
        requestedAt: Date = Date()
    ) {
        self.id = id
        self.appId = appId
        self.scopeIdentifier = scopeIdentifier
        self.justification = justification
        self.useCaseDescription = useCaseDescription
        self.expectedVolume = expectedVolume
        self.policyURL = policyURL
        self.status = status
        self.requestedAt = requestedAt
    }
}

public struct ScopeAuditEvent: Identifiable, Codable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var eventType: String // e.g. "Grant", "Revoke"
    public var scopeIdentifier: String
    public var appID: UUID?
    public var actorID: UUID

    public init(id: UUID = UUID(), timestamp: Date = Date(), eventType: String, scopeIdentifier: String, appID: UUID? = nil, actorID: UUID) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.scopeIdentifier = scopeIdentifier
        self.appID = appID
        self.actorID = actorID
    }
}

public struct ScopeTemplate: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var scopeIdentifiers: [String]

    public init(id: UUID = UUID(), name: String, scopeIdentifiers: [String] = []) {
        self.id = id
        self.name = name
        self.scopeIdentifiers = scopeIdentifiers
    }
}
