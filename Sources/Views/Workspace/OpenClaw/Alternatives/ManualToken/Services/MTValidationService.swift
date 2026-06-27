import Foundation

actor MTValidationService {
    static let shared = MTValidationService()
    func validate(token: String, host: String, port: Int, deviceInfo: LADeviceInfo) async throws -> MTTrustToken {
        // Implementation
        return MTTrustToken(token: UUID().uuidString, deviceId: UUID().uuidString, gatewayId: UUID().uuidString, expiresAt: Date().addingTimeInterval(3600))
    }
}
