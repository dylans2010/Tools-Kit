import Foundation

enum GmailModuleConfig {
    private static let fallbackClientID = "127870730797-v3g6ftqrp3q86pkfoa6uomsb8inj79ku.apps.googleusercontent.com"
    private static let fallbackRedirectScheme = "com.googleusercontent.apps.127870730797-v3g6ftqrp3q86pkfoa6uomsb8inj79ku"

    static var clientID: String {
        configuredValue(primaryKey: "GMAIL_OAUTH_CLIENT_ID", fallbackKey: "GOOGLE_OAUTH_CLIENT_ID") ?? fallbackClientID
    }

    static var redirectScheme: String {
        if let configuredURI = configuredValue(primaryKey: "GMAIL_OAUTH_REDIRECT_URI", fallbackKey: "GOOGLE_OAUTH_REDIRECT_URI"),
           let components = URLComponents(string: configuredURI),
           let scheme = components.scheme,
           !scheme.isEmpty {
            return scheme
        }
        return fallbackRedirectScheme
    }

    static let redirectPath = "/oauthredirect"
    static var redirectURI: String {
        "\(redirectScheme):\(redirectPath)"
    }
    static let oauthScopes = [
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.send"
    ]

    private static func configuredValue(primaryKey: String, fallbackKey: String? = nil) -> String? {
        if let value = infoPlistValue(forKey: primaryKey) { return value }
        if let value = configPlistValue(forKey: primaryKey) { return value }

        if let fallbackKey {
            if let value = infoPlistValue(forKey: fallbackKey) { return value }
            if let value = configPlistValue(forKey: fallbackKey) { return value }
        }
        return nil
    }

    private static func infoPlistValue(forKey key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func configPlistValue(forKey key: String) -> String? {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let value = plist[key] as? String
        else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct GmailTokenBundle: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let emailAddress: String
}

struct GmailInboxPage: Decodable, Sendable {
    let messages: [GmailMessageRef]
    let nextPageToken: String?
}

struct GmailMessageRef: Decodable, Sendable {
    let id: String
    let threadId: String
}

struct GmailMessageResponse: Decodable, Sendable {
    let id: String
    let threadId: String
    let labelIds: [String]?
    let internalDate: String?
    let payload: GmailPayload?
}

struct GmailPayload: Decodable, Sendable {
    let mimeType: String?
    let body: GmailBody?
    let headers: [GmailHeader]?
    let parts: [GmailPayload]?

    func flattenedHeaders() -> [String: String] {
        var result: [String: String] = [:]
        for header in headers ?? [] {
            result[header.name.lowercased()] = header.value
        }
        return result
    }

    func firstBody(for mimeType: String) -> GmailBody? {
        if self.mimeType?.lowercased() == mimeType.lowercased(), let body, body.data != nil {
            return body
        }
        for part in parts ?? [] {
            if let match = part.firstBody(for: mimeType) {
                return match
            }
        }
        return nil
    }
}

struct GmailHeader: Decodable, Sendable {
    let name: String
    let value: String
}

struct GmailBody: Decodable, Sendable {
    let data: String?
}

struct GmailSendRequest: Encodable, Sendable {
    let raw: String
}

struct GmailModifyRequest: Encodable, Sendable {
    let addLabelIds: [String]
    let removeLabelIds: [String]
}

struct GmailDraftRequest: Encodable, Sendable {
    let message: GmailSendRequest
}

struct GmailOAuthTokenResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

struct GmailProfileResponse: Decodable, Sendable {
    let emailAddress: String
}

struct GmailEmptyResponse: Decodable, Sendable {
    init() {}
}

struct GmailThread: Sendable {
    let id: String
    let subject: String
    let messages: [MailMessage]
    let lastMessageDate: Date
}

extension GmailBody {
    func decodedBody() -> String? {
        guard let data else { return nil }
        let normalized = data
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padded = normalized.padding(
            toLength: ((normalized.count + 3) / 4) * 4,
            withPad: "=",
            startingAt: 0
        )
        guard let rawData = Data(base64Encoded: padded) else { return nil }
        return String(data: rawData, encoding: .utf8)
    }
}

extension Data {
    func gmailBase64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
