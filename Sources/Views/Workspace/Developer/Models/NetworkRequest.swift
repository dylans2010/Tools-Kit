import Foundation

public struct NetworkRequest: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID?
    public var url: String
    public var method: String
    public var statusCode: Int
    public var duration: TimeInterval
    public var timestamp: Date

    public init(id: UUID = UUID(), appID: UUID? = nil, url: String, method: String, statusCode: Int, duration: TimeInterval, timestamp: Date = Date()) {
        self.id = id
        self.appID = appID
        self.url = url
        self.method = method
        self.statusCode = statusCode
        self.duration = duration
        self.timestamp = timestamp
    }
}
