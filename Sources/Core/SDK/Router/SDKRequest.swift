import Foundation

/// Structured request object for the SDK internal API system.
public struct SDKRequest: Identifiable, @unchecked Sendable {
    public let id: UUID
    public let path: String
    public let method: SDKRoute.Method
    public let parameters: [String: String]
    public let body: Data?
    public let headers: [String: String]
    public let context: SDKContext
    public let timestamp: Date

    public init(
        path: String,
        method: SDKRoute.Method = .get,
        parameters: [String: String] = [:],
        body: Data? = nil,
        headers: [String: String] = [:],
        context: SDKContext = SDKContext()
    ) {
        self.id = UUID()
        self.path = path
        self.method = method
        self.parameters = parameters
        self.body = body
        self.headers = headers
        self.context = context
        self.timestamp = Date()
    }

    public func decodedBody<T: Decodable>(_ type: T.Type) -> T? {
        guard let body = body else { return nil }
        return try? JSONDecoder().decode(type, from: body)
    }
}
