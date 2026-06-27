import Foundation

public actor MTHTTPClient {
    public static let shared = MTHTTPClient()
    private init() {}

    public func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await URLSession.shared.data(for: request)
    }
}
