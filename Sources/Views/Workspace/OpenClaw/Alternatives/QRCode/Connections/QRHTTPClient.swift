import Foundation

public actor QRHTTPClient {
    public static let shared = QRHTTPClient()
    private init() {}

    public func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await URLSession.shared.data(for: request)
    }
}
