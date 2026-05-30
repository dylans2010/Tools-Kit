import Foundation

public struct RemoteConfig: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var key: String
    public var value: String
    public var description: String

    public init(id: UUID = UUID(), appID: UUID, key: String, value: String, description: String = "") {
        self.id = id
        self.appID = appID
        self.key = key
        self.value = value
        self.description = description
    }
}
