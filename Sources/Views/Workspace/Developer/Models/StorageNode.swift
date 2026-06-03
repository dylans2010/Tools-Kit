import Foundation

public struct StorageNode: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID?
    public var name: String
    public var type: String
    public var usedSize: String
    public var totalSize: String
    public var usage: Double
    public var status: String

    public init(id: UUID = UUID(), appID: UUID? = nil, name: String, type: String, usedSize: String, totalSize: String, usage: Double, status: String = "HEALTHY") {
        self.id = id
        self.appID = appID
        self.name = name
        self.type = type
        self.usedSize = usedSize
        self.totalSize = totalSize
        self.usage = usage
        self.status = status
    }
}
