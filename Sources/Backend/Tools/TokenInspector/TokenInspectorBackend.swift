import Foundation

struct TokenAnalysis: @unchecked Sendable {
    var tokenType: TokenType = .unknown
    var header: [String: Any] = [:]
    var payload: [String: Any] = [:]
    var rawHeader = ""
    var rawPayload = ""
    var isExpired = false
    var expiresAt: Date?
    var issuedAt: Date?
    var issuer: String?
    var subject: String?
    var algorithm: String?
    var warnings: [String] = []
    var signaturePresent = false

    enum TokenType: String, Sendable {
        case jwt = "JSON Web Token (JWT)"
        case bearer = "Bearer Token"
        case apiKey = "API Key"
        case base64 = "Base64 Encoded"
        case unknown = "Unknown"
    }
}

@MainActor
final class TokenInspectorBackend: ObservableObject {
    @Published var token = ""
    @Published var analysis: TokenAnalysis?
    @Published var errorMessage = ""

    func inspect() {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = ""
        analysis = nil

        var result = TokenAnalysis()

        let parts = trimmed.components(separatedBy: ".")
        if parts.count == 3 {
            result.tokenType = .jwt
            result.signaturePresent = !parts[2].isEmpty
            if let headerData = base64URLDecode(parts[0]),
               let headerJSON = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any] {
                result.header = headerJSON
                result.rawHeader = formatJSON(headerJSON)
                result.algorithm = headerJSON["alg"] as? String
            } else {
                errorMessage = "Failed to decode JWT header"
                return
            }
            if let payloadData = base64URLDecode(parts[1]),
               let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
                result.payload = payloadJSON
                result.rawPayload = formatJSON(payloadJSON)
                if let exp = payloadJSON["exp"] as? TimeInterval {
                    result.expiresAt = Date(timeIntervalSince1970: exp)
                    result.isExpired = result.expiresAt! < Date()
                }
                if let iat = payloadJSON["iat"] as? TimeInterval {
                    result.issuedAt = Date(timeIntervalSince1970: iat)
                }
                result.issuer = payloadJSON["iss"] as? String
                result.subject = payloadJSON["sub"] as? String
            } else {
                errorMessage = "Failed to decode JWT payload"
                return
            }
            if result.algorithm == "none" { result.warnings.append("⚠️ Algorithm 'none' is insecure") }
            if result.algorithm?.hasPrefix("HS") == true { result.warnings.append("⚠️ Symmetric signing – keep secret key private") }
            if result.isExpired { result.warnings.append("⚠️ Token is expired") }
            if !result.signaturePresent { result.warnings.append("⚠️ Missing signature segment") }
        } else if trimmed.hasPrefix("Bearer ") {
            result.tokenType = .bearer
            result.rawPayload = String(trimmed.dropFirst(7))
        } else if Data(base64Encoded: trimmed) != nil {
            result.tokenType = .base64
            result.rawPayload = String(data: Data(base64Encoded: trimmed)!, encoding: .utf8) ?? "(binary)"
        } else if trimmed.count >= 20 && !trimmed.contains(" ") {
            result.tokenType = .apiKey
            result.rawPayload = "Opaque API Key – \(trimmed.count) characters"
        }

        analysis = result
    }

    func clear() {
        token = ""
        analysis = nil
        errorMessage = ""
    }

    private func base64URLDecode(_ string: String) -> Data? {
        var s = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let remainder = s.count % 4
        if remainder > 0 { s += String(repeating: "=", count: 4 - remainder) }
        return Data(base64Encoded: s)
    }

    private func formatJSON(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}
