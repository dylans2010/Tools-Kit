import Foundation

public actor LAHTTPClient {
    public static let shared = LAHTTPClient()
    private init() {}

    public func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await URLSession.shared.data(for: request)
    }
}
