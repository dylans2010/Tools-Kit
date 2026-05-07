import Foundation

/// Structured response object for the SDK internal API system.
public struct SDKResponse: Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let status: Status
    public let data: [String: String]
    public let error: String?
    public let timestamp: Date
    public var latency: TimeInterval

    public enum Status: String, Codable {
        case success, error, notFound, unauthorized, rateLimited
    }

    public init(
        requestId: UUID,
        status: Status,
        data: [String: String] = [:],
        error: String? = nil
    ) {
        self.id = UUID()
        self.requestId = requestId
        self.status = status
        self.data = data
        self.error = error
        self.timestamp = Date()
        self.latency = 0
    }

    public var isSuccess: Bool { status == .success }
}
