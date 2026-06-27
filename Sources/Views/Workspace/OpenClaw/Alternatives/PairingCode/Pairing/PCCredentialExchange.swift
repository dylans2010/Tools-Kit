import Foundation

public actor PCCredentialExchange {
    public static let shared = PCCredentialExchange()
    private init() {}

    public func processResponse(_ response: PCValidationResponse) async throws -> PCTrustToken {
        return PCTrustToken(token: response.trustToken, deviceId: response.deviceId, gatewayId: response.gatewayId, expiresAt: response.expiresAt)
    }
}
