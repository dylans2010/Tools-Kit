import Foundation

public actor PCTrustManager {
    public static let shared = PCTrustManager()
    private let tokenService = PCTokenService.shared

    private init() {}

    public func isTrusted(gatewayId: String) async throws -> Bool {
        if let token = try await tokenService.getToken(for: gatewayId) {
            return token.expiresAt > Date()
        }
        return false
    }
}
