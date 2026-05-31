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


public struct ThreadMetric: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var utilization: Double
    public var activeTime: Int

    public init(id: UUID = UUID(), name: String, utilization: Double, activeTime: Int) {
        self.id = id
        self.name = name
        self.utilization = utilization
        self.activeTime = activeTime
    }
}

public struct PerformanceReport: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var p99Latency: Int
    public var avgFPS: Double
    public var coldStartTime: Int
    public var peakMemoryMB: Int
    public var threadMetrics: [ThreadMetric]
    public var generatedAt: Date

    public init(
        id: UUID = UUID(),
        appID: UUID,
        p99Latency: Int,
        avgFPS: Double,
        coldStartTime: Int,
        peakMemoryMB: Int,
        threadMetrics: [ThreadMetric] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.appID = appID
        self.p99Latency = p99Latency
        self.avgFPS = avgFPS
        self.coldStartTime = coldStartTime
        self.peakMemoryMB = peakMemoryMB
        self.threadMetrics = threadMetrics
        self.generatedAt = generatedAt
    }
}
