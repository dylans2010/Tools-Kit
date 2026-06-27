import Foundation

public actor MTCredentialExchange {
    public static let shared = MTCredentialExchange()
    private init() {}

    public func exchange(token: MTTrustToken) async throws {
        // Persistent storage is already handled by the service,
        // this would handle any additional handshake if needed.
    }
}
