import Foundation

public struct AgentAPIResponseHandler {
    public init() {}

    public func handle<T: Decodable>(_ data: Data, response: HTTPURLResponse) throws -> T {
        guard (200...299).contains(response.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentAPIError.serverError(response.statusCode, message)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AgentAPIError.decodingError(error)
        }
    }
}
