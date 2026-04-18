import AuthenticationServices
import CryptoKit
import Foundation
import SwiftUI

final class GmailProvider: NSObject, MailProvider, ASWebAuthenticationPresentationContextProviding {
    var displayName: String { "Gmail" }
    var iconAssetName: String { "envelope.badge.fill" }
    var primaryColor: Color { Color(red: 0.86, green: 0.20, blue: 0.18) }

    private var authSession: ASWebAuthenticationSession?
    private let baseURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me")!
    private let daysPerPage = 14

    private static let scope = "https://mail.google.com/"

    func authenticate(credentials: MailCredentials) async throws -> MailSession {
        let remoteVariables = await fetchRemoteVariables()
        let clientID = try oauthValue(primaryKey: "GMAIL_OAUTH_CLIENT_ID", fallbackKey: "GOOGLE_OAUTH_CLIENT_ID", remoteVariables: remoteVariables)
        let redirectURI = try oauthValue(primaryKey: "GMAIL_OAUTH_REDIRECT_URI", fallbackKey: "GOOGLE_OAUTH_REDIRECT_URI", remoteVariables: remoteVariables)
        try validateRedirectURI(redirectURI)

        let verifier = randomCodeVerifier()
        let challenge = codeChallenge(from: verifier)
        let state = UUID().uuidString

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Self.scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let url = components.url else {
            throw NSError(domain: "GmailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to build OAuth URL"])
        }

        let callback = try await startOAuth(url: url, callbackScheme: URL(string: redirectURI)?.scheme)
        let callbackComponents = URLComponents(url: callback, resolvingAgainstBaseURL: false)
        let returnedState = callbackComponents?.queryItems?.first(where: { $0.name == "state" })?.value
        guard returnedState == state else {
            throw NSError(domain: "GmailProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid OAuth state"])
        }
        guard let code = callbackComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "GmailProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing authorization code"])
        }

        let token = try await exchangeCode(code: code, verifier: verifier, clientID: clientID, redirectURI: redirectURI)
        let profile = try await fetchProfile(accessToken: token.accessToken)

        return MailSession(
            provider: .gmail,
            email: profile.email,
            displayName: profile.name ?? "Gmail",
            accessToken: token.accessToken,
            refreshToken: token.refreshToken
        )
    }

    func fetchInbox(session: MailSession, page: Int) async throws -> [MailMessage] {
        var items = [URLQueryItem(name: "maxResults", value: "30")]
        if page > 0 {
            items.append(URLQueryItem(name: "q", value: "newer_than:\(page * daysPerPage)d"))
        }

        let listURL = baseURL.appendingPathComponent("messages").appending(queryItems: items)
        let list: GmailListResponse = try await request(url: listURL, body: Optional<Data>.none, token: session.accessToken)

        var messages: [MailMessage] = []
        for item in list.messages ?? [] {
            messages.append(try await fetchMessage(session: session, id: item.id))
        }

        return messages.sorted(by: { $0.date > $1.date })
    }

    func fetchMessage(session: MailSession, id: String) async throws -> MailMessage {
        let url = baseURL.appendingPathComponent("messages/\(id)").appending(queryItems: [URLQueryItem(name: "format", value: "full")])
        let payload: GmailMessagePayload = try await request(url: url, body: Optional<Data>.none, token: session.accessToken)

        let headers = payload.payload?.headers.reduce(into: [String: String]()) { partial, item in
            partial[item.name.lowercased()] = item.value
        } ?? [:]

        let bodySelection = preferredBody(payload.payload)
        let parsedDate = gmailDate(payload.internalDate, fallback: headers["date"])

        return MailMessage(
            id: payload.id,
            threadId: payload.threadId,
            from: headers["from"] ?? "Unknown",
            to: splitAddress(headers["to"]),
            cc: splitAddress(headers["cc"]),
            bcc: splitAddress(headers["bcc"]),
            subject: headers["subject"] ?? "No Subject",
            body: bodySelection.plain,
            htmlBody: bodySelection.html,
            date: parsedDate,
            isRead: !(payload.labelIds ?? []).contains("UNREAD"),
            isStarred: (payload.labelIds ?? []).contains("STARRED"),
            attachments: []
        )
    }

    func sendMessage(session: MailSession, draft: MailDraft) async throws {
        let raw = buildRFC2822(draft: draft)
        let body = GmailSendBody(raw: Data(raw.utf8).base64URLEncodedString())
        let url = baseURL.appendingPathComponent("messages/send")
        try await requestVoid(url: url, method: "POST", body: body, token: session.accessToken)
    }

    func saveDraft(session: MailSession, draft: MailDraft) async throws {
        let raw = buildRFC2822(draft: draft)
        let body = GmailDraftBody(message: GmailSendBody(raw: Data(raw.utf8).base64URLEncodedString()))
        let url = baseURL.appendingPathComponent("drafts")
        try await requestVoid(url: url, method: "POST", body: body, token: session.accessToken)
    }

    func deleteMessage(session: MailSession, id: String) async throws {
        let url = baseURL.appendingPathComponent("messages/\(id)")
        try await requestVoid(url: url, method: "DELETE", body: Optional<Data>.none, token: session.accessToken)
    }

    func markRead(session: MailSession, id: String) async throws {
        let body = GmailModifyBody(addLabelIds: [], removeLabelIds: ["UNREAD"])
        let url = baseURL.appendingPathComponent("messages/\(id)/modify")
        try await requestVoid(url: url, method: "POST", body: body, token: session.accessToken)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { ASPresentationAnchor() }

    private func startOAuth(url: URL, callbackScheme: String?) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callback, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callback else {
                    continuation.resume(throwing: NSError(domain: "GmailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing callback URL"]))
                    return
                }
                continuation.resume(returning: callback)
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            authSession = session
            _ = session.start()
        }
    }

    private func oauthValue(primaryKey: String, fallbackKey: String? = nil, remoteVariables: [String: String] = [:]) throws -> String {
        if let value = localConfigValue(forKey: primaryKey) {
            return value
        }
        if let value = infoPlistValue(forKey: primaryKey) {
            return value
        }
        if let value = remoteConfigValue(forKey: primaryKey, remoteVariables: remoteVariables) {
            return value
        }

        if let fallbackKey {
            if let value = localConfigValue(forKey: fallbackKey) {
                return value
            }
            if let value = infoPlistValue(forKey: fallbackKey) {
                return value
            }
            if let value = remoteConfigValue(forKey: fallbackKey, remoteVariables: remoteVariables) {
                return value
            }
        }

        throw NSError(
            domain: "GmailProvider",
            code: 500,
            userInfo: [
                NSLocalizedDescriptionKey: "Missing OAuth config key \(primaryKey)"
            ]
        )
    }

    private func localConfigValue(forKey key: String) -> String? {
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

    private func infoPlistValue(forKey key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func remoteConfigValue(forKey key: String, remoteVariables: [String: String]) -> String? {
        guard let value = remoteVariables[key] else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func fetchRemoteVariables() async -> [String: String] {
        guard
            let rawURL = localConfigValue(forKey: "APPWRITE_MAIL_CONFIG_URL"),
            let url = URL(string: rawURL)
        else {
            return [:]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let bearer = localConfigValue(forKey: "APPWRITE_MAIL_CONFIG_BEARER") {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return [:]
            }

            if let direct = try? JSONDecoder().decode([String: String].self, from: data) {
                return direct
            }

            if
                let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let payload = object["data"] as? [String: String]
            {
                return payload
            }

            return [:]
        } catch {
            return [:]
        }
    }

    private func validateRedirectURI(_ redirectURI: String) throws {
        if redirectURI.lowercased().hasPrefix("appwrite-callback-") {
            throw NSError(
                domain: "GmailProvider",
                code: 500,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid Gmail OAuth redirect URI. Direct Gmail OAuth cannot use an Appwrite callback URI. Set GMAIL_OAUTH_REDIRECT_URI to a native Google OAuth redirect URI (for example, com.googleusercontent.apps.<client-id>:/oauthredirect)."
                ]
            )
        }
    }

    private func exchangeCode(code: String, verifier: String, clientID: String, redirectURI: String) async throws -> OAuthTokenResponse {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let fields = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code_verifier", value: verifier)
        ]

        request.httpBody = fields
            .map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "GmailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Token exchange failed"])
        }

        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }

    private func fetchProfile(accessToken: String) async throws -> GoogleProfile {
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "GmailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Profile request failed"])
        }
        return try JSONDecoder().decode(GoogleProfile.self, from: data)
    }

    private func request<T: Decodable, Body: Encodable>(url: URL, method: String = "GET", body: Body? = nil, token: String?) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "GmailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Gmail API request failed"])
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func requestVoid<Body: Encodable>(url: URL, method: String = "GET", body: Body? = nil, token: String?) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "GmailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Gmail API request failed"])
        }
    }

    private func preferredBody(_ part: GmailMIMEPart?) -> (plain: String, html: String?) {
        guard let part else { return ("", nil) }

        if part.mimeType?.lowercased() == "text/html", let decoded = part.body?.decodedData {
            let html = String(decoding: decoded, as: UTF8.self)
            return (plainText(from: html), html)
        }

        if part.mimeType?.lowercased() == "text/plain", let decoded = part.body?.decodedData {
            return (String(decoding: decoded, as: UTF8.self), nil)
        }

        for child in part.parts ?? [] where child.mimeType?.lowercased() == "text/html" {
            if let decoded = child.body?.decodedData {
                let html = String(decoding: decoded, as: UTF8.self)
                return (plainText(from: html), html)
            }
        }

        for child in part.parts ?? [] where child.mimeType?.lowercased() == "text/plain" {
            if let decoded = child.body?.decodedData {
                return (String(decoding: decoded, as: UTF8.self), nil)
            }
        }

        for child in part.parts ?? [] {
            let nested = preferredBody(child)
            if nested.html != nil || !nested.plain.isEmpty {
                return nested
            }
        }

        return ("", nil)
    }

    private func plainText(from html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func splitAddress(_ value: String?) -> [String] {
        (value ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func gmailDate(_ internalDate: String?, fallback: String?) -> Date {
        if let internalDate, let ms = Double(internalDate) {
            return Date(timeIntervalSince1970: ms / 1000)
        }

        if let fallback {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            if let date = formatter.date(from: fallback) {
                return date
            }
        }

        return Date()
    }

    private func buildRFC2822(draft: MailDraft) -> String {
        let boundary = "Boundary-\(UUID().uuidString)"
        var lines = [
            "From: \(draft.from)",
            "To: \(draft.to.joined(separator: ", "))",
            draft.cc.isEmpty ? nil : "Cc: \(draft.cc.joined(separator: ", "))",
            draft.bcc.isEmpty ? nil : "Bcc: \(draft.bcc.joined(separator: ", "))",
            "Subject: \(encodedHeader(draft.subject))",
            "MIME-Version: 1.0"
        ].compactMap { $0 }

        if let html = draft.bodyHTML {
            lines.append("Content-Type: multipart/alternative; boundary=\"\(boundary)\"")
            lines.append("")
            lines.append("--\(boundary)")
            lines.append("Content-Type: text/plain; charset=utf-8")
            lines.append("")
            lines.append(draft.bodyText)
            lines.append("--\(boundary)")
            lines.append("Content-Type: text/html; charset=utf-8")
            lines.append("")
            lines.append(html)
            lines.append("--\(boundary)--")
        } else {
            lines.append("Content-Type: text/plain; charset=utf-8")
            lines.append("")
            lines.append(draft.bodyText)
        }

        return lines.joined(separator: "\r\n")
    }

    private func encodedHeader(_ value: String) -> String {
        guard let data = value.data(using: .utf8) else { return value }
        let needsEncoding = value.unicodeScalars.contains(where: { $0.value > 127 })
        guard needsEncoding else { return value }
        return "=?UTF-8?B?\(data.base64EncodedString())?="
    }

    private func randomCodeVerifier() -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return String((0..<64).compactMap { _ in chars.randomElement() })
    }

    private func codeChallenge(from verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private struct OAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

private struct GoogleProfile: Decodable {
    let email: String
    let name: String?
}

private struct GmailListResponse: Decodable {
    struct Item: Decodable {
        let id: String
    }
    let messages: [Item]?
}

private struct GmailMessagePayload: Decodable {
    let id: String
    let threadId: String
    let internalDate: String?
    let labelIds: [String]?
    let payload: GmailMIMEPart?
}

private struct GmailMIMEPart: Decodable {
    let mimeType: String?
    let headers: [GmailHeader]
    let body: GmailBody?
    let parts: [GmailMIMEPart]?
}

private struct GmailHeader: Decodable {
    let name: String
    let value: String
}

private struct GmailBody: Decodable {
    let data: String?

    var decodedData: Data? {
        guard let data else { return nil }
        let normalized = data
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padded = normalized.padding(toLength: ((normalized.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        return Data(base64Encoded: padded)
    }
}

private struct GmailSendBody: Encodable {
    let raw: String
}

private struct GmailDraftBody: Encodable {
    let message: GmailSendBody
}

private struct GmailModifyBody: Encodable {
    let addLabelIds: [String]
    let removeLabelIds: [String]
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
