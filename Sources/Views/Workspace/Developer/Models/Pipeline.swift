import Foundation

public enum PipelineStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case running = "Running"
    case success = "Success"
    case failed = "Failed"
}

public struct PipelineStage: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var status: PipelineStatus
    public var logs: String

    public init(id: UUID = UUID(), name: String, status: PipelineStatus = .pending, logs: String = "") {
        self.id = id
        self.name = name
        self.status = status
        self.logs = logs
    }
}

public struct Pipeline: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var status: PipelineStatus
    public var lastRunAt: Date
    public var triggerSource: String
    public var stages: [PipelineStage]

    public init(id: UUID = UUID(), name: String, status: PipelineStatus = .pending, lastRunAt: Date = Date(), triggerSource: String = "Manual", stages: [PipelineStage] = []) {
        self.id = id
        self.name = name
        self.status = status
        self.lastRunAt = lastRunAt
        self.triggerSource = triggerSource
        self.stages = stages
    }
}
