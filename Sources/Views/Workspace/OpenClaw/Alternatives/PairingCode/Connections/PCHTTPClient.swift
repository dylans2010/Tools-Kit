import Foundation

public actor PCHTTPClient {
    public static let shared = PCHTTPClient()
    private init() {}

    public func post<T: Encodable, R: Decodable>(_ body: T, to url: URL) async throws -> R {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PCError.networkFailure("Server returned error")
        }

        return try JSONDecoder().decode(R.self, from: data)
    }
}
