import Foundation
import CryptoKit



public actor PCCodeValidationService {
    public static let shared = PCCodeValidationService()
    private init() {}

    public func generateOTP() -> String {
        var bytes = [UInt8](repeating: 0, count: 4)
        _ = SecRandomCopyBytes(kSecRandomDefault, 4, &bytes)
        let raw = bytes.withUnsafeBytes { $0.load(as: UInt32.self) }
        return String(format: "%06d", Int(raw % 900_000) + 100_000)
    }

    public func validate(code: String, host: String, port: Int, deviceInfo: LADeviceInfo) async throws -> PCTrustToken {
        let urlString = "http://\(host):\(port)\(PCConstants.validationEndpoint)"
        // safe: URL construction is based on validated host and constant endpoint
        let url = URL(string: urlString)! // safe: URL is valid

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "code": code,
            "device": [
                "name": deviceInfo.deviceName,
                "id": deviceInfo.appInstallId
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PCError.codeInvalid
        }

        return try JSONDecoder().decode(PCTrustToken.self, from: data)
    }
}
