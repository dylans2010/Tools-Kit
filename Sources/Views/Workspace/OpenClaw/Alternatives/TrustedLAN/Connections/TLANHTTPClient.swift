import Foundation
public actor TLANHTTPClient {
    public static let shared = TLANHTTPClient(); private init() {}
    public func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) { return try await URLSession.shared.data(for: request) }
}
