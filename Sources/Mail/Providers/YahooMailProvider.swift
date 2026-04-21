import AuthenticationServices
import CryptoKit
import Foundation
import SwiftUI

final class YahooMailProvider: NSObject, MailProvider, StandardMailProvider, ASWebAuthenticationPresentationContextProviding {
    var displayName: String { "Yahoo Mail" }
    var iconAssetName: String { "mail.and.text.magnifyingglass" }
    var primaryColor: Color { Color(red: 0.38, green: 0.20, blue: 0.67) }

    private var authSession: ASWebAuthenticationSession?
    private let imapFallback = IMAPProvider()
    private let boundSession: MailSession?

    init(session: MailSession? = nil) {
        self.boundSession = session
        super.init()
    }

    func authenticate(credentials: MailCredentials) async throws -> MailSession {
        let remoteVariables = await fetchRemoteVariables()
        let clientID = try oauthValue(primaryKey: "YAHOO_CLIENT_ID", fallbackKey: "YAHOO_OAUTH_CLIENT_ID", remoteVariables: remoteVariables)
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

        InternalLogger.shared.log("OAuth start provider=yahoo callbackScheme=\(URL(string: redirectURI)?.scheme ?? "unknown")", level: .info)
        let callback = try await startOAuth(url: url, callbackScheme: URL(string: redirectURI)?.scheme)

        let callbackString = callback.absoluteString.replacingOccurrences(of: "toolskit://oauth/yahoo?", with: "toolskit://oauth/yahoo/?")
        let callbackComponents = URLComponents(string: callbackString)
        let returnedState = callbackComponents?.queryItems?.first(where: { $0.name == "state" })?.value
        guard returnedState == state else {
            throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "OAuth state mismatch"])
        }
        guard let code = callbackComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing authorization code"])
        }

        InternalLogger.shared.log("OAuth callback provider=yahoo state=validated", level: .info)
        InternalLogger.shared.log("OAuth token exchange provider=yahoo", level: .info)
        let token = try await exchangeCode(code: code, verifier: verifier, clientID: clientID, redirectURI: redirectURI)
        let email: String
        if !credentials.email.isEmpty {
            email = credentials.email
        } else if let guid = token.xoauthYahooGuid, !guid.isEmpty {
            email = guid
        } else {
            throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve Yahoo account identity"])
        }

        let sessionID = UUID().uuidString
        _ = MailKeychainManager.shared.saveOAuthTokens(accountId: sessionID, accessToken: token.accessToken, refreshToken: token.refreshToken)

        return MailSession(
            id: sessionID,
            provider: .yahoo,
            email: email,
            displayName: "Yahoo Mail",
            imapHost: "imap.mail.yahoo.com",
            imapPort: 993,
            smtpHost: "smtp.mail.yahoo.com",
            smtpPort: 465
        )
    }

    func fetchInbox(session: MailSession, page: Int) async throws -> [MailMessage] {
        try validateSessionProvider(session, expected: .yahoo)
        do {
            return try await fetchInboxPrimary(session: session, page: page, forceRefresh: false)
        } catch {
            let ns = error as NSError
            if ns.code == 401 {
                do {
                    return try await fetchInboxPrimary(session: session, page: page, forceRefresh: true)
                } catch {}
            }
            return try await fallbackInbox(session: session, page: page)
        }
    }

    func fetchMessage(session: MailSession, id: String) async throws -> MailMessage {
        try validateSessionProvider(session, expected: .yahoo)
        do {
            return try await fetchMessagePrimary(session: session, id: id, forceRefresh: false)
        } catch {
            let ns = error as NSError
            if ns.code == 401 {
                do { return try await fetchMessagePrimary(session: session, id: id, forceRefresh: true) } catch {}
            }
            let list = try await fallbackInbox(session: session, page: 0)
            if let matched = list.first(where: { $0.id == id }) {
                return matched
            }
            throw NSError(domain: "YahooProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "Yahoo message not found"])
        }
    }

    func sendMessage(session: MailSession, draft: MailDraft) async throws {
        try validateSessionProvider(session, expected: .yahoo)
        try await imapFallback.sendMessage(session: fallbackSession(session), draft: draft)
    }

    func saveDraft(session: MailSession, draft: MailDraft) async throws {
        try validateSessionProvider(session, expected: .yahoo)
        try await imapFallback.saveDraft(session: fallbackSession(session), draft: draft)
    }

    func deleteMessage(session: MailSession, id: String) async throws {
        try validateSessionProvider(session, expected: .yahoo)
        do {
            let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
            let token = try await getAccessToken(for: session, forceRefresh: false)
            let _: YahooDeleteResponse = try await apiRequest(url: url, payload: YahooDeleteRequest(mid: id), token: token)
        } catch {
            let ns = error as NSError
            if ns.code == 401 {
                let token = try await getAccessToken(for: session, forceRefresh: true)
                let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
                let _: YahooDeleteResponse = try await apiRequest(url: url, payload: YahooDeleteRequest(mid: id), token: token)
                return
            }
            try await imapFallback.deleteMessage(session: fallbackSession(session), id: id)
        }
    }

    func markRead(session: MailSession, id: String) async throws {
        try validateSessionProvider(session, expected: .yahoo)
        do {
            let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
            let token = try await getAccessToken(for: session, forceRefresh: false)
            let _: YahooUpdateResponse = try await apiRequest(url: url, payload: YahooUpdateReadRequest(mid: id, unread: false), token: token)
        } catch {
            let ns = error as NSError
            if ns.code == 401 {
                let token = try await getAccessToken(for: session, forceRefresh: true)
                let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
                let _: YahooUpdateResponse = try await apiRequest(url: url, payload: YahooUpdateReadRequest(mid: id, unread: false), token: token)
                return
            }
            try await imapFallback.markRead(session: fallbackSession(session), id: id)
        }
    }

    func startPushStyleUpdates(session: MailSession) async {
        try? await imapFallback.idle(session: fallbackSession(session), seconds: 30)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { ASPresentationAnchor() }

    private func getAccessToken(for session: MailSession, forceRefresh: Bool) async throws -> String {
        try await AccountManager.shared.token(for: session.id, provider: .yahoo, forceRefresh: forceRefresh)
    }

    private func fetchInboxPrimary(session: MailSession, page: Int, forceRefresh: Bool) async throws -> [MailMessage] {
        let pageSize = 30
        let start = page * pageSize
        let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
        let request = YahooListRequest(startInfo: start, numInfo: pageSize)
        let token = try await getAccessToken(for: session, forceRefresh: forceRefresh)
        let response: YahooListEnvelope = try await apiRequest(url: url, payload: request, token: token)

        return response.result.messages.map {
            MailMessage(id: $0.messageId, threadId: $0.threadId ?? "msg-\($0.messageId)", from: $0.from, to: [], cc: [], bcc: [], subject: $0.subject, body: $0.snippet ?? "", htmlBody: nil, date: yahooDate($0.receivedDate), isRead: !$0.unread, isStarred: $0.flagged, attachments: [])
        }
    }

    private func fetchMessagePrimary(session: MailSession, id: String, forceRefresh: Bool) async throws -> MailMessage {
        let url = URL(string: "https://api.mail.yahoo.com/ws/mail/v1.1/jsonrpc")!
        let token = try await getAccessToken(for: session, forceRefresh: forceRefresh)
        let response: YahooMessageEnvelope = try await apiRequest(url: url, payload: YahooMessageRequest(mid: id), token: token)
        let item = response.result.message
        return MailMessage(id: item.messageId, threadId: item.threadId ?? "msg-\(item.messageId)", from: item.from, to: item.to, cc: item.cc, bcc: item.bcc, subject: item.subject, body: item.bodyText ?? "", htmlBody: item.bodyHTML, date: yahooDate(item.receivedDate), isRead: !item.unread, isStarred: item.flagged, attachments: [])
    }

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
            imapHost: "imap.mail.yahoo.com",
            imapPort: 993,
            smtpHost: "smtp.mail.yahoo.com",
            smtpPort: 465
        )
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
        AppConfig.string(for: key)
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
        guard let token, !token.isEmpty else {
            throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing Yahoo access token"])
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Yahoo access token rejected"])
            }
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

    func refreshSessionToken(session: MailSession) async throws -> MailSession {
        try validateSessionProvider(session, expected: .yahoo)
        guard let tokens = MailKeychainManager.shared.getOAuthTokens(accountId: session.id),
              let refreshToken = tokens.refreshToken, !refreshToken.isEmpty else {
            throw NSError(domain: "YahooProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing Yahoo refresh token"])
        }
        let remoteVariables = await fetchRemoteVariables()
        let clientID = try oauthValue(primaryKey: "YAHOO_CLIENT_ID", fallbackKey: "YAHOO_OAUTH_CLIENT_ID", remoteVariables: remoteVariables)
        let redirectURI = try oauthValue(primaryKey: "YAHOO_OAUTH_REDIRECT_URI", remoteVariables: remoteVariables)

        var request = URLRequest(url: URL(string: "https://api.login.yahoo.com/oauth2/get_token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let fields = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        request.httpBody = fields
            .map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "YahooProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Yahoo token refresh failed"])
        }
        let refreshed = try JSONDecoder().decode(YahooToken.self, from: data)
        let resolvedRefresh = refreshed.refreshToken ?? refreshToken
        _ = MailKeychainManager.shared.saveOAuthTokens(accountId: session.id, accessToken: refreshed.accessToken, refreshToken: resolvedRefresh)
        await MainActor.run {
            MailStore.shared.updateAccountTokens(accountId: session.id, accessToken: refreshed.accessToken, refreshToken: resolvedRefresh, expiration: nil)
        }
        InternalLogger.shared.log("OAuth token exchange provider=yahoo status=refreshed", level: .info)
        return MailSession(
            id: session.id,
            provider: session.provider,
            email: session.email,
            displayName: session.displayName,
            imapHost: session.imapHost,
            imapPort: session.imapPort,
            smtpHost: session.smtpHost,
            smtpPort: session.smtpPort
        )
    }

    func fetchInbox() async throws -> [MailMessage] {
        let session = try await resolvedSession()
        return try await fetchInbox(session: session, page: 0)
    }

    func fetchMessage(id: String) async throws -> MailMessage {
        let session = try await resolvedSession()
        return try await fetchMessage(session: session, id: id)
    }

    func sendEmail(_ draft: MailDraft) async throws {
        let session = try await resolvedSession()
        try await sendMessage(session: session, draft: draft)
    }

    func refreshToken() async throws {
        let session = try await resolvedSession()
        _ = try await refreshSessionToken(session: session)
    }

    func listAccounts() async -> [MailAccount] {
        await MainActor.run {
            MailStore.shared.accounts.filter { $0.provider == .yahoo }
        }
    }

    private func resolvedSession() async throws -> MailSession {
        if let boundSession {
            return boundSession
        }
        let active = await MainActor.run { MailStore.shared.activeAccount }
        guard let active else {
            throw NSError(domain: "YahooProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "No active Yahoo account"])
        }
        return MailSession(
            id: active.id,
            provider: active.provider,
            email: active.emailAddress,
            displayName: active.displayName,
            imapHost: active.imapHost,
            imapPort: active.imapPort,
            smtpHost: active.smtpHost,
            smtpPort: active.smtpPort
        )
    }

    private func validateSessionProvider(_ session: MailSession, expected: MailAccount.ProviderType) throws {
        guard session.provider == expected else {
            throw NSError(domain: "YahooProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid session provider"])
        }
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
