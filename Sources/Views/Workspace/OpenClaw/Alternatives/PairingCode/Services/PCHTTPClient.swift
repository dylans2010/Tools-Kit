import Foundation

actor PCHTTPClient {
    func validate(code: String, host: String, port: Int, deviceInfo: LADeviceInfo) async throws -> PCTrustToken {
        let result = try await PCCodeValidationService.shared.validate(code: code, host: host, port: port, deviceInfo: deviceInfo)
        return PCTrustToken(token: result.token, deviceId: result.deviceId, gatewayId: result.gatewayId, expiresAt: result.expiresAt)
    }
}
