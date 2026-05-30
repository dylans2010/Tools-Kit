import Foundation

public struct Secret: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID?
    public var key: String
    public var maskedValue: String
    public var createdAt: Date

    public init(id: UUID = UUID(), appID: UUID? = nil, key: String, maskedValue: String, createdAt: Date = Date()) {
        self.id = id
        self.appID = appID
        self.key = key
        self.maskedValue = maskedValue
        self.createdAt = createdAt
    }
}
