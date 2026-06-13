import Foundation

public struct BridgeSession: Codable, Identifiable, Equatable {
    public let id: String
    public let deviceID: UUID
    public let createdAt: Date
    public var expiresAt: Date?
    public var isActive: Bool

    public init(id: String, deviceID: UUID, createdAt: Date = Date(), expiresAt: Date? = nil, isActive: Bool = true) {
        self.id = id
        self.deviceID = deviceID
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isActive = isActive
    }
}
