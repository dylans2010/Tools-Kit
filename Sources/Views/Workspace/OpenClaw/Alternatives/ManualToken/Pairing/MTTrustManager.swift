import Foundation

public actor MTTrustManager {
    public static let shared = MTTrustManager()
    private let tokenService = MTTokenService.shared

    private init() {}

    public func checkTrust(gatewayId: String) async throws -> Bool {
        if let token = try await tokenService.getToken(for: gatewayId) {
            return token.expiresAt > Date()
        }
        return false
    }
}
