import Foundation

public actor QRValidationService {
    public static let shared = QRValidationService()
    private init() {}

    public func validate(payload: QRPayload, deviceInfo: LADeviceInfo) async throws -> QRTrustToken {
        let urlString = "http://\(payload.host):\(payload.port)\(QRConstants.validationEndpoint)"
        guard let url = URL(string: urlString) else {
            throw QRError.validationFailed("Invalid URL")
        }

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
