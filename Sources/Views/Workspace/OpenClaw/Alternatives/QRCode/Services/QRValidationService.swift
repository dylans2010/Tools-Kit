import Foundation

public actor QRValidationService {
    public static let shared = QRValidationService()
    private init() {}

    public func validateToken(_ payload: QRPayload, deviceInfo: LADeviceInfo) async throws -> QRTrustToken {
        let url = URL(string: "http://\\(payload.host):\\(payload.port)\\(QRConstants.validationEndpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "token": payload.token,
            "gatewayId": payload.gatewayId,
            "deviceName": deviceInfo.deviceName,
            "deviceModel": deviceInfo.deviceModel,
            "platform": deviceInfo.platform,
            "appVersion": deviceInfo.appVersion,
            "appInstallId": deviceInfo.appInstallId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw QRError.validationFailed("Server rejected token")
        }

        return try JSONDecoder().decode(QRTrustToken.self, from: data)
    }
}
