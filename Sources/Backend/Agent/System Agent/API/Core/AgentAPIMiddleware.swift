import Foundation

protocol AgentAPIMiddleware {
    func process(request: URLRequest) async throws -> URLRequest
    func process(data: Data, response: URLResponse) async throws -> (Data, URLResponse)
}

struct LoggingMiddleware: AgentAPIMiddleware {
    init() {}
    func process(request: URLRequest) async throws -> URLRequest {
        AgentAPILogger.shared.log(.info, "Request: \(request.url?.absoluteString ?? "unknown")")
        return request
    }
    func process(data: Data, response: URLResponse) async throws -> (Data, URLResponse) {
        AgentAPILogger.shared.log(.info, "Response received")
        return (data, response)
    }
}
