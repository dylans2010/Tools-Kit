import Foundation

public enum APIKeyType: String, Codable, CaseIterable {
    case developerAPI = "Developer API"
    case webhookSigning = "Webhook Signing"
    case serviceAccount = "Service Account"
    case cli = "CLI"
    case publicReadOnly = "Public Read-Only"
}

public enum KeyEnvironment: String, Codable, CaseIterable {
    case live = "Live"
    case test = "Test"
}

public enum DeveloperKeyRevocationReason: String, Codable, CaseIterable {
    case compromised = "Compromised"
    case rotated = "Rotated"
    case noLongerNeeded = "No Longer Needed"
    case appDecommissioned = "App Decommissioned"
    case policyViolation = "Policy Violation"
    case other = "Other"
}

public struct KeyRotationRecord: Codable, Identifiable, Hashable {
    public var id: UUID
    public var rotatedAt: Date
    public var previousKeyMasked: String

    public init(id: UUID = UUID(), rotatedAt: Date = Date(), previousKeyMasked: String) {
        self.id = id
        self.rotatedAt = rotatedAt
        self.previousKeyMasked = previousKeyMasked
    }
}

public struct APIKey: Identifiable, Codable, Hashable {
    public var id: UUID
    public var value: String = ""
    public var maskedValue: String
    public var label: String
    public var type: APIKeyType
    public var environment: KeyEnvironment
    public var appID: UUID?
    public var scopeIdentifiers: [String]
    public var createdAt: Date
    public var lastUsedAt: Date?
    public var expiresAt: Date?
    public var isRevoked: Bool
    public var revokedAt: Date?
    public var revokedReason: DeveloperKeyRevocationReason?
    public var ipAllowlist: [String]
    public var notes: String
    public var rotationHistory: [KeyRotationRecord]

    public init(
        id: UUID = UUID(),
        maskedValue: String,
        label: String,
        type: APIKeyType,
        environment: KeyEnvironment,
        appID: UUID? = nil,
        scopeIdentifiers: [String] = [],
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        expiresAt: Date? = nil,
        isRevoked: Bool = false,
        revokedAt: Date? = nil,
        revokedReason: DeveloperKeyRevocationReason? = nil,
        ipAllowlist: [String] = [],
        notes: String = "",
        rotationHistory: [KeyRotationRecord] = []
    ) {
        self.id = id
        self.maskedValue = maskedValue
        self.label = label
        self.type = type
        self.environment = environment
        self.appID = appID
        self.scopeIdentifiers = scopeIdentifiers
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.expiresAt = expiresAt
        self.isRevoked = isRevoked
        self.revokedAt = revokedAt
        self.revokedReason = revokedReason
        self.ipAllowlist = ipAllowlist
        self.notes = notes
        self.rotationHistory = rotationHistory
    }
}
