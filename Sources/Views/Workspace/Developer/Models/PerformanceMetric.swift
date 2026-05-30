import Foundation

public struct PerformanceMetric: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var name: String
    public var value: Double
    public var unit: String
    public var timestamp: Date

    public init(id: UUID = UUID(), appID: UUID, name: String, value: Double, unit: String, timestamp: Date = Date()) {
        self.id = id
        self.appID = appID
        self.name = name
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
    }
}
