import Foundation

public enum FeatureFlagStatus: String, Codable, CaseIterable {
    case active = "Active"
    case disabled = "Disabled"
    case archived = "Archived"
}

public struct FeatureFlag: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var key: String
    public var name: String
    public var description: String
    public var status: FeatureFlagStatus
    public var isEnabled: Bool
    public var rolloutPercentage: Double
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        appID: UUID,
        key: String,
        name: String,
        description: String = "",
        status: FeatureFlagStatus = .active,
        isEnabled: Bool = false,
        rolloutPercentage: Double = 100.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.appID = appID
        self.key = key
        self.name = name
        self.description = description
        self.status = status
        self.isEnabled = isEnabled
        self.rolloutPercentage = rolloutPercentage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
