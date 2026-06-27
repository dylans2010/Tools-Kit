import Foundation
public actor TLANTrustManager {
    public static let shared = TLANTrustManager(); private let tokenService = TLANTokenService.shared; private init() {}
    public func checkTrust(for gatewayId: String) async throws -> Bool {
        if let token = try await tokenService.getToken(for: gatewayId) { return token.expiresAt > Date() }; return false
    }
    public func revokeTrust(for gatewayId: String) async { await tokenService.deleteToken(for: gatewayId) }
}
