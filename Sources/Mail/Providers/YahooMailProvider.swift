import AuthenticationServices
import CryptoKit
import Foundation
import SwiftUI

final class YahooMailProvider: NSObject, MailProvider, ASWebAuthenticationPresentationContextProviding {
    var displayName: String { "Yahoo Mail" }
    var iconAssetName: String { "mail.and.text.magnifyingglass" }
    var primaryColor: Color { Color(red: 0.38, green: 0.20, blue: 0.67) }

    private var authSession: ASWebAuthenticationSession?
    private let imapFallback = IMAPProvider()

    func authenticate(credentials: MailCredentials) async throws -> MailSession {
        let remoteVariables = await fetchRemoteVariables()
        let clientID = try oauthValue(primaryKey: "YAHOO_OAUTH_CLIENT_ID", remoteVariables: remoteVariables)
        let redirectURI = try oauthValue(primaryKey: "YAHOO_OAUTH_REDIRECT_URI", remoteVariables: remoteVariables)

        let verifier = randomCodeVerifier()
        let challenge = codeChallenge(from: verifier)
        let state = UUID().uuidString

        var components = URLComponents(string: "https://api.login.yahoo.com/oauth2/request_auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "mail-r mail-w"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let url = components.url else {
            throw NSError(domain: "YahooProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid OAuth URL"])
        }

        let callback = try await startOAuth(url: url, callbackScheme: URL(string: redirectURI)?.scheme)
        let callbackComponents = URLComponents(url: callback, resolvingAgainstBaseURL: false)
        let returnedState = callbackComponents?.queryItems?.first(where: { $0.name == "state" })?.value
        guard returnedState == state else {
            throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "OAuth state mismatch"])
        }
        guard let code = callbackComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing authorization code"])
        }

        let token = try await exchangeCode(code: code, verifier: verifier, clientID: clientID, redirectURI: redirectURI)
        let email: String
        if !credentials.email.isEmpty {
            email = credentials.email
        } else if let guid = token.xoauthYahooGuid, !guid.isEmpty {
            email = guid
        } else {
            throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve Yahoo account identity"])
        }

        return MailSession(
            provider: .yahoo,
            email: email,
            displayName: "Yahoo Mail",
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            imapHost: "imap.mail.yahoo.com",
            imapPort: 993,
            smtpHost: "smtp.mail.yahoo.com",
            smtpPort: 465
        )
    }

    func fetchInbox(session: MailSession, page: Int) async throws -> [MailMessage] {
        do {
            let pageSize = 30
            let start = page * pageSize
            let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
            let request = YahooListRequest(startInfo: start, numInfo: pageSize)
            let response: YahooListEnvelope = try await apiRequest(url: url, payload: request, token: session.accessToken)

            return response.result.messages.map {
                MailMessage(
                    id: $0.messageId,
                    threadId: $0.threadId ?? "msg-\($0.messageId)",
                    from: $0.from,
                    to: [],
                    cc: [],
                    bcc: [],
                    subject: $0.subject,
                    body: $0.snippet ?? "",
                    htmlBody: nil,
                    date: yahooDate($0.receivedDate),
                    isRead: !$0.unread,
                    isStarred: $0.flagged,
                    attachments: []
                )
            }
        } catch {
            return try await fallbackInbox(session: session, page: page)
        }
    }

    func fetchMessage(session: MailSession, id: String) async throws -> MailMessage {
        do {
            let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
            let response: YahooMessageEnvelope = try await apiRequest(url: url, payload: YahooMessageRequest(mid: id), token: session.accessToken)
            let item = response.result.message
            return MailMessage(
                id: item.messageId,
                threadId: item.threadId ?? "msg-\(item.messageId)",
                from: item.from,
                to: item.to,
                cc: item.cc,
                bcc: item.bcc,
                subject: item.subject,
                body: item.bodyText ?? "",
                htmlBody: item.bodyHTML,
                date: yahooDate(item.receivedDate),
                isRead: !item.unread,
                isStarred: item.flagged,
                attachments: []
            )
        } catch {
            let list = try await fallbackInbox(session: session, page: 0)
            return list.first(where: { $0.id == id }) ?? list.first ?? MailMessage(
                id: id,
                threadId: "msg-\(id)",
                from: "Unknown",
                to: [],
                cc: [],
                bcc: [],
                subject: "No Subject",
                body: "",
                htmlBody: nil,
                date: Date(),
                isRead: false,
                isStarred: false,
                attachments: []
            )
        }
    }

    func sendMessage(session: MailSession, draft: MailDraft) async throws {
        try await imapFallback.sendMessage(session: fallbackSession(session), draft: draft)
    }

    func saveDraft(session: MailSession, draft: MailDraft) async throws {
        try await imapFallback.saveDraft(session: fallbackSession(session), draft: draft)
    }

    func deleteMessage(session: MailSession, id: String) async throws {
        do {
            let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
            let _: YahooDeleteResponse = try await apiRequest(url: url, payload: YahooDeleteRequest(mid: id), token: session.accessToken)
        } catch {
            try await imapFallback.deleteMessage(session: fallbackSession(session), id: id)
        }
    }

    func markRead(session: MailSession, id: String) async throws {
        do {
            let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
            let _: YahooUpdateResponse = try await apiRequest(url: url, payload: YahooUpdateReadRequest(mid: id, unread: false), token: session.accessToken)
        } catch {
            try await imapFallback.markRead(session: fallbackSession(session), id: id)
        }
    }

    func startPushStyleUpdates(session: MailSession) async {
        try? await imapFallback.idle(session: fallbackSession(session), seconds: 30)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { ASPresentationAnchor() }

    private func fallbackInbox(session: MailSession, page: Int) async throws -> [MailMessage] {
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else {
            throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing credentials for IMAP fallback"])
        }

        let fallbackCredentials = MailCredentials(
            email: session.email,
            password: password,
            host: "imap.mail.yahoo.com",
            port: 993,
            smtpHost: "smtp.mail.yahoo.com",
            smtpPort: 465,
            accessToken: nil,
            refreshToken: nil
        )
        let fallbackSession = try await imapFallback.authenticate(credentials: fallbackCredentials)
        return try await imapFallback.fetchInbox(session: fallbackSession, page: page)
    }

    private func fallbackSession(_ session: MailSession) -> MailSession {
        MailSession(
            id: session.id,
            provider: .imap,
            email: session.email,
            displayName: session.displayName,
            accessToken: nil,
            refreshToken: nil,
            imapHost: "imap.mail.yahoo.com",
            imapPort: 993,
            smtpHost: "smtp.mail.yahoo.com",
            smtpPort: 465
        )
    }

    private func oauthValue(primaryKey: String, remoteVariables: [String: String] = [:]) throws -> String {
        if let value = localConfigValue(forKey: primaryKey) {
            return value
        }
        if let value = infoPlistValue(forKey: primaryKey) {
            return value
        }
        if let value = remoteConfigValue(forKey: primaryKey, remoteVariables: remoteVariables) {
            return value
        }

        throw NSError(domain: "YahooProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing \(primaryKey)"])
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

    private func startOAuth(url: URL, callbackScheme: String?) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callback, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callback else {
                    continuation.resume(throwing: NSError(domain: "YahooProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing callback URL"]))
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

    private func exchangeCode(code: String, verifier: String, clientID: String, redirectURI: String) async throws -> YahooToken {
        var request = URLRequest(url: URL(string: "https://api.login.yahoo.com/oauth2/get_token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let fields = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "code_verifier", value: verifier)
        ]

        request.httpBody = fields
            .map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "YahooProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Token exchange failed"])
        }

        return try JSONDecoder().decode(YahooToken.self, from: data)
    }

    private func apiRequest<T: Decodable, Body: Encodable>(url: URL, payload: Body, token: String?) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "YahooProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Yahoo API failed"])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func yahooDate(_ value: String?) -> Date {
        guard let value else { return Date() }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value) ?? Date()
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

private struct YahooToken: Decodable {
    let accessToken: String
    let refreshToken: String?
    let xoauthYahooGuid: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case xoauthYahooGuid = "xoauth_yahoo_guid"
    }
}

private struct YahooListRequest: Encodable {
    let method = "ListMessages"
    let params: [String: Int]

    init(startInfo: Int, numInfo: Int) {
        self.params = ["startInfo": startInfo, "numInfo": numInfo]
    }
}

private struct YahooListEnvelope: Decodable {
    struct Result: Decodable {
        let messages: [YahooListMessage]
    }

    let result: Result
}

private struct YahooListMessage: Decodable {
    let messageId: String
    let threadId: String?
    let from: String
    let subject: String
    let receivedDate: String?
    let snippet: String?
    let unread: Bool
    let flagged: Bool
}

private struct YahooMessageRequest: Encodable {
    let method = "GetMessage"
    let params: [String: String]

    init(mid: String) {
        self.params = ["mid": mid]
    }
}

private struct YahooMessageEnvelope: Decodable {
    struct Result: Decodable {
        let message: YahooMessage
    }

    let result: Result
}

private struct YahooMessage: Decodable {
    let messageId: String
    let threadId: String?
    let from: String
    let to: [String]
    let cc: [String]
    let bcc: [String]
    let subject: String
    let bodyText: String?
    let bodyHTML: String?
    let receivedDate: String?
    let unread: Bool
    let flagged: Bool
}

private struct YahooDeleteRequest: Encodable {
    let method = "DeleteMessage"
    let params: [String: String]

    init(mid: String) {
        self.params = ["mid": mid]
    }
}

private struct YahooDeleteResponse: Decodable {}

private struct YahooUpdateReadRequest: Encodable {
    let method = "FlagMessage"
    let params: [String: String]

    init(mid: String, unread: Bool) {
        self.params = ["mid": mid, "unread": unread ? "1" : "0"]
    }
}

private struct YahooUpdateResponse: Decodable {}
