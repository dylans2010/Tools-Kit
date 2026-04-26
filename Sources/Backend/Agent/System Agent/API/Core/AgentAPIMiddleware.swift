import Foundation

public protocol AgentAPIMiddleware {
    func process(request: URLRequest) async throws -> URLRequest
    func process(data: Data, response: URLResponse) async throws -> (Data, URLResponse)
}

public struct LoggingMiddleware: AgentAPIMiddleware {
    public init() {}
    public func process(request: URLRequest) async throws -> URLRequest {
        AgentAPILogger.shared.log(.info, "Request: \(request.url?.absoluteString ?? "unknown")")
        return request
    }
    public func process(data: Data, response: URLResponse) async throws -> (Data, URLResponse) {
        AgentAPILogger.shared.log(.info, "Response received")
        return (data, response)
    }
}
