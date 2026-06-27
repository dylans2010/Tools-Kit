import Foundation

public actor QRTrustManager {
    public static let shared = QRTrustManager()
    private let tokenService = QRTokenService.shared

    private init() {}

    public func isTrusted(gatewayId: String) async throws -> Bool {
        if let token = try await tokenService.getToken(for: gatewayId) {
            return token.expiresAt > Date()
        }
        return false
    }
}
