import Foundation

actor MTValidationService {
    static let shared = MTValidationService()
    private init() {}

    func validate(token: String, host: String, port: Int, deviceInfo: LADeviceInfo) async throws -> MTTrustToken {
        let urlString = "http://\(host):\(port)\(MTConstants.validationEndpoint)"
        guard let url = URL(string: urlString) else { throw MTError.invalidFormat }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "token": token,
            "device": [
                "name": deviceInfo.deviceName,
                "id": deviceInfo.appInstallId
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw MTError.tokenInvalid
        }

        return try JSONDecoder().decode(MTTrustToken.self, from: data)
    }
}
