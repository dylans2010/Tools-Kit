import Foundation

public enum NodeStatus: String, Codable, CaseIterable {
    case healthy = "Healthy"
    case degraded = "Degraded"
    case down = "Down"
}

public struct InfrastructureNode: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var type: String
    public var region: String
    public var status: NodeStatus
    public var cpuUsage: Double
    public var memoryUsage: Double

    public init(id: UUID = UUID(), name: String, type: String, region: String, status: NodeStatus = .healthy, cpuUsage: Double = 0.0, memoryUsage: Double = 0.0) {
        self.id = id
        self.name = name
        self.type = type
        self.region = region
        self.status = status
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
    }
}
