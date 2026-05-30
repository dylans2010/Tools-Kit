import Foundation

public enum PipelineStatus: String, Codable, CaseIterable {
    case queued = "Queued"
    case building = "Building"
    case testing = "Testing"
    case success = "Success"
    case failed = "Failed"
}

public struct Pipeline: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var branch: String
    public var commitHash: String
    public var status: PipelineStatus
    public var duration: TimeInterval?
    public var createdAt: Date

    public init(id: UUID = UUID(), appID: UUID, branch: String, commitHash: String, status: PipelineStatus = .queued, duration: TimeInterval? = nil, createdAt: Date = Date()) {
        self.id = id
        self.appID = appID
        self.branch = branch
        self.commitHash = commitHash
        self.status = status
        self.duration = duration
        self.createdAt = createdAt
    }
}
