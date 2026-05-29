import Foundation

public struct PrivacyManifest: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var apiUsageReasons: [String]
    public var dataCollectionTypes: [String]
    public var updatedAt: Date

    public init(id: UUID = UUID(), appID: UUID, apiUsageReasons: [String] = [], dataCollectionTypes: [String] = [], updatedAt: Date = Date()) {
        self.id = id
        self.appID = appID
        self.apiUsageReasons = apiUsageReasons
        self.dataCollectionTypes = dataCollectionTypes
        self.updatedAt = updatedAt
    }
}
