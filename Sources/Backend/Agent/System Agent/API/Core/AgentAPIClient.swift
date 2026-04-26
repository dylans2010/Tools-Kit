import Foundation

struct AgentAPIClient {
    func send(request: URLRequest, session: URLSession = .shared) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AgentAPIError.unexpectedResponse
        }
        return (data, http)
    }
}
