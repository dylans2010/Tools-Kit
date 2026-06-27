import Foundation

public actor LATrustManager {
    public static let shared = LATrustManager()
    private let tokenService = LATokenService.shared

    private init() {}

    public func checkTrust(gatewayId: String) async throws -> Bool {
        if let token = try await tokenService.getToken(for: gatewayId) {
            return token.expiresAt > Date()
        }
        return false
    }
}
