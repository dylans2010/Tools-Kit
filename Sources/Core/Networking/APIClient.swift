import Foundation

class APIClient {
    static let shared = APIClient()

    private init() {}

    func request<T: Decodable>(_ url: URL, method: String = "GET", body: Data? = nil) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
