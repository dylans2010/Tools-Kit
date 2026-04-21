import AuthenticationServices
import CryptoKit
import Foundation
import SwiftUI

final class OutlookProvider: NSObject, MailProvider, ASWebAuthenticationPresentationContextProviding {
    var displayName: String { "Outlook" }
    var iconAssetName: String { "mail.stack" }
    var primaryColor: Color { Color(red: 0.00, green: 0.47, blue: 0.90) }

    private var authSession: ASWebAuthenticationSession?
    private var nextLinksByPage: [Int: String] = [:]
    private let microsoftScopes = "User.Read Mail.Read Mail.ReadWrite Mail.Send offline_access openid profile email"

    func authenticate(credentials: MailCredentials) async throws -> MailSession {
        let remoteVariables = await fetchRemoteVariables()
        let clientID = try oauthValue(primaryKey: "MICROSOFT_CLIENT_ID", fallbackKey: "MICROSOFT_OAUTH_CLIENT_ID", remoteVariables: remoteVariables)
        let redirectURI = "msauth.com.dylans2010.ToolsKit://auth"

        let verifier = randomCodeVerifier()
        let challenge = codeChallenge(from: verifier)
        let state = UUID().uuidString

        var components = URLComponents(string: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_mode", value: "query"),
            URLQueryItem(name: "scope", value: microsoftScopes),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let url = components.url else {
            throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid OAuth URL"])
        }

        InternalLogger.shared.log("OAuth start provider=microsoft callbackScheme=msauth.com.dylans2010.ToolsKit", level: .info)
        let callback = try await startOAuth(url: url, callbackScheme: "msauth.com.dylans2010.ToolsKit")
        let returnedState = callbackValue("state", from: callback)
        guard returnedState == state else {
            throw NSError(domain: "OutlookProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "OAuth state mismatch"])
        }
        guard let code = callbackValue("code", from: callback), !code.isEmpty else {
            throw NSError(domain: "OutlookProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing authorization code"])
        }

        InternalLogger.shared.log("OAuth callback provider=microsoft state=validated", level: .info)
        InternalLogger.shared.log("OAuth token exchange provider=microsoft", level: .info)
        let token = try await exchangeCode(code: code, verifier: verifier, clientID: clientID, redirectURI: redirectURI)
        let profile = try await fetchProfile(accessToken: token.accessToken)

        let sessionID = UUID().uuidString
        _ = MailKeychainManager.shared.saveOAuthTokens(accountId: sessionID, accessToken: token.accessToken, refreshToken: token.refreshToken)

        return MailSession(
            id: sessionID,
            provider: .outlook,
            email: profile.mail ?? profile.userPrincipalName ?? credentials.email,
            displayName: profile.displayName ?? "Outlook"
        )
    }

    func fetchInbox(session: MailSession, page: Int) async throws -> [MailMessage] {
        do {
            return try await fetchInboxImpl(session: session, page: page, forceRefresh: false)
        } catch {
            let ns = error as NSError
            guard ns.code == 401 else { throw error }
            return try await fetchInboxImpl(session: session, page: page, forceRefresh: true)
        }
    }

    func fetchMessage(session: MailSession, id: String) async throws -> MailMessage {
        do {
            return try await fetchMessageImpl(session: session, id: id, forceRefresh: false)
        } catch {
            let ns = error as NSError
            guard ns.code == 401 else { throw error }
            return try await fetchMessageImpl(session: session, id: id, forceRefresh: true)
        }
    }

    func sendMessage(session: MailSession, draft: MailDraft) async throws {
        do {
            try await sendMessageImpl(session: session, draft: draft, forceRefresh: false)
        } catch {
            let ns = error as NSError
            guard ns.code == 401 else { throw error }
            try await sendMessageImpl(session: session, draft: draft, forceRefresh: true)
        }
    }

    func saveDraft(session: MailSession, draft: MailDraft) async throws {
        try await saveDraftImpl(session: session, draft: draft, forceRefresh: false)
    }

    func deleteMessage(session: MailSession, id: String) async throws {
        try await deleteMessageImpl(session: session, id: id, forceRefresh: false)
    }

    func markRead(session: MailSession, id: String) async throws {
        try await markReadImpl(session: session, id: id, forceRefresh: false)
    }

    private func fetchInboxImpl(session: MailSession, page: Int, forceRefresh: Bool) async throws -> [MailMessage] {
        try validateSessionProvider(session, expected: .outlook)
        let endpoint: URL
        if page == 0 {
            endpoint = URL(string: "https://graph.microsoft.com/v1.0/me/messages?$top=30&$orderby=receivedDateTime%20desc")!
        } else if let next = nextLinksByPage[page] {
            guard let parsed = URL(string: next) else {
                throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid pagination URL"])
            }
            endpoint = parsed
        } else {
            endpoint = URL(string: "https://graph.microsoft.com/v1.0/me/messages?$top=30&$orderby=receivedDateTime%20desc")!
        }

        let token = try await AccountManager.shared.token(for: session.id, provider: .outlook, forceRefresh: forceRefresh)
        let response: GraphMessagesResponse = try await request(url: endpoint, body: Optional<Data>.none, token: token)
        if let next = response.nextLink { nextLinksByPage[page + 1] = next }
        return response.value.map {
            MailMessage(id: $0.id, threadId: $0.conversationId, from: $0.from?.emailAddress.address ?? "Unknown", to: $0.toRecipients?.compactMap { $0.emailAddress.address } ?? [], cc: $0.ccRecipients?.compactMap { $0.emailAddress.address } ?? [], bcc: [], subject: $0.subject ?? "No Subject", body: $0.body?.content ?? "", htmlBody: $0.body?.contentType.lowercased() == "html" ? $0.body?.content : nil, date: isoDate($0.receivedDateTime), isRead: $0.isRead ?? false, isStarred: $0.flag?.flagStatus?.lowercased() == "flagged", attachments: [])
        }
    }

    private func fetchMessageImpl(session: MailSession, id: String, forceRefresh: Bool) async throws -> MailMessage {
        try validateSessionProvider(session, expected: .outlook)
        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages/\(id)") else {
            throw NSError(domain: "OutlookProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid message identifier"])
        }
        let token = try await AccountManager.shared.token(for: session.id, provider: .outlook, forceRefresh: forceRefresh)
        let item: GraphMessage = try await request(url: url, body: Optional<Data>.none, token: token)
        return MailMessage(id: item.id, threadId: item.conversationId, from: item.from?.emailAddress.address ?? "Unknown", to: item.toRecipients?.compactMap { $0.emailAddress.address } ?? [], cc: item.ccRecipients?.compactMap { $0.emailAddress.address } ?? [], bcc: [], subject: item.subject ?? "No Subject", body: item.body?.content ?? "", htmlBody: item.body?.contentType.lowercased() == "html" ? item.body?.content : nil, date: isoDate(item.receivedDateTime), isRead: item.isRead ?? false, isStarred: item.flag?.flagStatus?.lowercased() == "flagged", attachments: [])
    }

    private func sendMessageImpl(session: MailSession, draft: MailDraft, forceRefresh: Bool) async throws {
        try validateSessionProvider(session, expected: .outlook)
        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me/sendMail") else { throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid Microsoft send endpoint"]) }
        let body = GraphSendMailBody(message: .init(subject: draft.subject, body: .init(contentType: draft.bodyHTML == nil ? "Text" : "HTML", content: draft.bodyHTML ?? draft.bodyText), toRecipients: draft.to.map { .init(emailAddress: .init(address: $0)) }, ccRecipients: draft.cc.map { .init(emailAddress: .init(address: $0)) }), saveToSentItems: true)
        let token = try await AccountManager.shared.token(for: session.id, provider: .outlook, forceRefresh: forceRefresh)
        try await requestVoid(url: url, method: "POST", body: body, token: token)
    }

    private func saveDraftImpl(session: MailSession, draft: MailDraft, forceRefresh: Bool) async throws {
        try validateSessionProvider(session, expected: .outlook)
        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages") else { throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid Microsoft draft endpoint"]) }
        let body = GraphDraftBody(subject: draft.subject, body: .init(contentType: draft.bodyHTML == nil ? "Text" : "HTML", content: draft.bodyHTML ?? draft.bodyText), toRecipients: draft.to.map { .init(emailAddress: .init(address: $0)) }, ccRecipients: draft.cc.map { .init(emailAddress: .init(address: $0)) })
        let token = try await AccountManager.shared.token(for: session.id, provider: .outlook, forceRefresh: forceRefresh)
        let _: GraphMessage = try await request(url: url, method: "POST", body: body, token: token)
    }

    private func deleteMessageImpl(session: MailSession, id: String, forceRefresh: Bool) async throws {
        try validateSessionProvider(session, expected: .outlook)
        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages/\(id)") else { throw NSError(domain: "OutlookProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid message identifier"]) }
        let token = try await AccountManager.shared.token(for: session.id, provider: .outlook, forceRefresh: forceRefresh)
        try await requestVoid(url: url, method: "DELETE", body: Optional<Data>.none, token: token)
    }

    private func markReadImpl(session: MailSession, id: String, forceRefresh: Bool) async throws {
        try validateSessionProvider(session, expected: .outlook)
        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages/\(id)") else { throw NSError(domain: "OutlookProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid message identifier"]) }
        let body = ["isRead": true]
        let token = try await AccountManager.shared.token(for: session.id, provider: .outlook, forceRefresh: forceRefresh)
        let _: GraphMessage = try await request(url: url, method: "PATCH", body: body, token: token)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { ASPresentationAnchor() }

    private func getAccessToken(for session: MailSession) async throws -> String {
        try await AccountManager.shared.token(for: session.id, provider: .outlook)
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

        throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing \(primaryKey)"])
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
                    continuation.resume(throwing: NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing callback URL"]))
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

    private func exchangeCode(code: String, verifier: String, clientID: String, redirectURI: String) async throws -> GraphToken {
        var request = URLRequest(url: URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let fields = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_verifier", value: verifier),
            URLQueryItem(name: "scope", value: microsoftScopes)
        ]

        request.httpBody = formURLEncoded(fields)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Token exchange failed"])
        }

        return try JSONDecoder().decode(GraphToken.self, from: data)
    }

    private func fetchProfile(accessToken: String) async throws -> GraphProfile {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me")!
        return try await request(url: url, body: Optional<Data>.none, token: accessToken)
    }

    private func callbackValue(_ name: String, from url: URL) -> String? {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let value = queryItems.first(where: { $0.name == name })?.value {
            return value
        }

        guard let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment else { return nil }
        var parts = URLComponents()
        parts.query = fragment
        return parts.queryItems?.first(where: { $0.name == name })?.value
    }

    private func formURLEncoded(_ items: [URLQueryItem]) -> Data? {
        var components = URLComponents()
        components.queryItems = items
        return components.percentEncodedQuery?.data(using: .utf8)
    }

    private func request<T: Decodable, Body: Encodable>(url: URL, method: String = "GET", body: Body? = nil, token: String?) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let token, !token.isEmpty else {
            throw NSError(domain: "OutlookProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing Microsoft access token"])
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                throw NSError(domain: "OutlookProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Microsoft access token rejected"])
            }
            throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Graph request failed"])
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func requestVoid<Body: Encodable>(url: URL, method: String = "GET", body: Body? = nil, token: String?) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let token, !token.isEmpty else {
            throw NSError(domain: "OutlookProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing Microsoft access token"])
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                throw NSError(domain: "OutlookProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Microsoft access token rejected"])
            }
            throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Graph request failed"])
        }
    }

    private func isoDate(_ value: String?) -> Date {
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
        try validateSessionProvider(session, expected: .outlook)
        guard let tokens = MailKeychainManager.shared.getOAuthTokens(accountId: session.id),
              let refreshToken = tokens.refreshToken, !refreshToken.isEmpty else {
            throw NSError(domain: "OutlookProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing Microsoft refresh token"])
        }
        let remoteVariables = await fetchRemoteVariables()
        let clientID = try oauthValue(primaryKey: "MICROSOFT_CLIENT_ID", fallbackKey: "MICROSOFT_OAUTH_CLIENT_ID", remoteVariables: remoteVariables)
        let redirectURI = try oauthValue(primaryKey: "MICROSOFT_OAUTH_REDIRECT_URI", remoteVariables: remoteVariables)

        var request = URLRequest(url: URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let fields = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: microsoftScopes)
        ]
        request.httpBody = formURLEncoded(fields)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Microsoft token refresh failed"])
        }
        let refreshed = try JSONDecoder().decode(GraphToken.self, from: data)
        let resolvedRefresh = refreshed.refreshToken ?? refreshToken
        _ = MailKeychainManager.shared.saveOAuthTokens(accountId: session.id, accessToken: refreshed.accessToken, refreshToken: resolvedRefresh)
        await MainActor.run {
            MailStore.shared.updateAccountTokens(accountId: session.id, accessToken: refreshed.accessToken, refreshToken: resolvedRefresh, expiration: nil)
        }
        InternalLogger.shared.log("OAuth token exchange provider=microsoft status=refreshed", level: .info)
        return MailSession(
            id: session.id,
            provider: session.provider,
            email: session.email,
            displayName: session.displayName
        )
    }

    private func validateSessionProvider(_ session: MailSession, expected: MailAccount.ProviderType) throws {
        guard session.provider == expected else {
            throw NSError(domain: "OutlookProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid session provider"])
        }
    }
}

private struct GraphToken: Decodable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

private struct GraphProfile: Decodable {
    let displayName: String?
    let userPrincipalName: String?
    let mail: String?
}

private struct GraphMessagesResponse: Decodable {
    let value: [GraphMessage]
    let nextLink: String?

    enum CodingKeys: String, CodingKey {
        case value
        case nextLink = "@odata.nextLink"
    }
}

private struct GraphMessage: Decodable {
    let id: String
    let conversationId: String
    let subject: String?
    let body: GraphBody?
    let from: GraphRecipient?
    let toRecipients: [GraphRecipient]?
    let ccRecipients: [GraphRecipient]?
    let receivedDateTime: String?
    let isRead: Bool?
    let flag: GraphFlag?
}

private struct GraphFlag: Decodable {
    let flagStatus: String?
}

private struct GraphBody: Codable {
    let contentType: String
    let content: String
}

private struct GraphRecipient: Codable {
    let emailAddress: GraphEmail
}

private struct GraphEmail: Codable {
    let address: String
}

private struct GraphSendMailBody: Encodable {
    struct Message: Encodable {
        let subject: String
        let body: GraphBody
        let toRecipients: [GraphRecipient]
        let ccRecipients: [GraphRecipient]
    }

    let message: Message
    let saveToSentItems: Bool
}

private struct GraphDraftBody: Encodable {
    let subject: String
    let body: GraphBody
    let toRecipients: [GraphRecipient]
    let ccRecipients: [GraphRecipient]
}
