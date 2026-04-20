import Foundation

enum GmailModuleConfig {
    static var clientID: String {
        AppConfig.googleClientID
    }

    static var redirectScheme: String {
        if let components = URLComponents(string: AppConfig.googleRedirectURI),
           let scheme = components.scheme, !scheme.isEmpty {
            return scheme
        }
        return "com.ToolsKit.google"
    }

    static let redirectPath = "/oauthredirect"
    static var redirectURI: String {
        "\(redirectScheme):\(redirectPath)"
    }
    static let oauthScopes = [
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://www.googleapis.com/auth/gmail.send",
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/userinfo.profile"
    ]
}

struct GmailTokenBundle: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let emailAddress: String
}

struct GmailInboxPage: Decodable, Sendable {
    let messages: [GmailMessageRef]?
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
    let filename: String?
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
    let size: Int?
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

func gmailFormURLEncodedBody(_ items: [URLQueryItem]) -> Data? {
    let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&="))
    return items
        .map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: allowed) ?? "")" }
        .joined(separator: "&")
        .data(using: .utf8)
}
