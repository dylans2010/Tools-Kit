import Foundation

/// Core API client for interacting with ToolsKit backend services.
final class APIClient {
    nonisolated(unsafe) static let shared = APIClient()

    private let baseURL = URL(string: "https://api.toolskit.io/v1")!
    private let session = URLSession.shared

    private init() {}

    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        // request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    enum APIError: Error, Sendable {
        case requestFailed
        case decodingFailed
    }
}
