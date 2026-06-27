import Foundation

actor PCHTTPClient {
    func validate(code: String, host: String, port: Int, deviceInfo: LADeviceInfo) async throws -> PCTrustToken {
        guard let url = URL(string: "http://\(host):\(port)/alt/pairing-code/validate") else {
            throw PCErrors.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // In real impl, we would encode this properly
        return PCTrustToken(token: UUID().uuidString, deviceId: UUID().uuidString, gatewayId: UUID().uuidString, expiresAt: Date().addingTimeInterval(3600*24*30))
    }
}

public struct PCTrustToken: Codable {
    public let token: String
    public let deviceId: String
    public let gatewayId: String
    public let expiresAt: Date
}
