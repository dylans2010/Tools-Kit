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

    func authenticate(credentials: MailCredentials) async throws -> MailSession {
        let clientID = try oauthValue(key: "MICROSOFT_OAUTH_CLIENT_ID")
        let redirectURI = try oauthValue(key: "MICROSOFT_OAUTH_REDIRECT_URI")

        let verifier = randomCodeVerifier()
        let challenge = codeChallenge(from: verifier)
        let state = UUID().uuidString

        var components = URLComponents(string: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_mode", value: "query"),
            URLQueryItem(name: "scope", value: "Mail.ReadWrite Mail.Send offline_access"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let url = components.url else {
            throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid OAuth URL"])
        }

        let callback = try await startOAuth(url: url, callbackScheme: URL(string: redirectURI)?.scheme)
        let callbackComponents = URLComponents(url: callback, resolvingAgainstBaseURL: false)
        let returnedState = callbackComponents?.queryItems?.first(where: { $0.name == "state" })?.value
        guard returnedState == state else {
            throw NSError(domain: "OutlookProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "OAuth state mismatch"])
        }
        guard let code = callbackComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "OutlookProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing authorization code"])
        }

        let token = try await exchangeCode(code: code, verifier: verifier, clientID: clientID, redirectURI: redirectURI)
        let profile = try await fetchProfile(accessToken: token.accessToken)

        return MailSession(
            provider: .outlook,
            email: profile.mail ?? profile.userPrincipalName ?? credentials.email,
            displayName: profile.displayName ?? "Outlook",
            accessToken: token.accessToken,
            refreshToken: token.refreshToken
        )
    }

    func fetchInbox(session: MailSession, page: Int) async throws -> [MailMessage] {
        let endpoint: URL
        if page == 0 {
            endpoint = URL(string: "https://graph.microsoft.com/v1.0/me/messages?$top=30&$orderby=receivedDateTime%20desc")!
        } else if let next = nextLinksByPage[page] {
            endpoint = URL(string: next)!
        } else {
            endpoint = URL(string: "https://graph.microsoft.com/v1.0/me/messages?$top=30&$orderby=receivedDateTime%20desc")!
        }

        let response: GraphMessagesResponse = try await request(url: endpoint, body: Optional<Data>.none, token: session.accessToken)
        if let next = response.nextLink {
            nextLinksByPage[page + 1] = next
        }

        return response.value.map {
            MailMessage(
                id: $0.id,
                threadId: $0.conversationId,
                from: $0.from?.emailAddress.address ?? "Unknown",
                to: $0.toRecipients?.compactMap { $0.emailAddress.address } ?? [],
                cc: $0.ccRecipients?.compactMap { $0.emailAddress.address } ?? [],
                bcc: [],
                subject: $0.subject ?? "No Subject",
                body: $0.body?.content ?? "",
                htmlBody: $0.body?.contentType.lowercased() == "html" ? $0.body?.content : nil,
                date: isoDate($0.receivedDateTime),
                isRead: $0.isRead ?? false,
                isStarred: $0.flag?.flagStatus?.lowercased() == "flagged",
                attachments: []
            )
        }
    }

    func fetchMessage(session: MailSession, id: String) async throws -> MailMessage {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages/\(id)")!
        let item: GraphMessage = try await request(url: url, body: Optional<Data>.none, token: session.accessToken)
        return MailMessage(
            id: item.id,
            threadId: item.conversationId,
            from: item.from?.emailAddress.address ?? "Unknown",
            to: item.toRecipients?.compactMap { $0.emailAddress.address } ?? [],
            cc: item.ccRecipients?.compactMap { $0.emailAddress.address } ?? [],
            bcc: [],
            subject: item.subject ?? "No Subject",
            body: item.body?.content ?? "",
            htmlBody: item.body?.contentType.lowercased() == "html" ? item.body?.content : nil,
            date: isoDate(item.receivedDateTime),
            isRead: item.isRead ?? false,
            isStarred: item.flag?.flagStatus?.lowercased() == "flagged",
            attachments: []
        )
    }

    func sendMessage(session: MailSession, draft: MailDraft) async throws {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/sendMail")!
        let body = GraphSendMailBody(
            message: .init(
                subject: draft.subject,
                body: .init(contentType: draft.bodyHTML == nil ? "Text" : "HTML", content: draft.bodyHTML ?? draft.bodyText),
                toRecipients: draft.to.map { .init(emailAddress: .init(address: $0)) },
                ccRecipients: draft.cc.map { .init(emailAddress: .init(address: $0)) }
            ),
            saveToSentItems: true
        )

        try await requestVoid(url: url, method: "POST", body: body, token: session.accessToken)
    }

    func saveDraft(session: MailSession, draft: MailDraft) async throws {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages")!
        let body = GraphDraftBody(
            subject: draft.subject,
            body: .init(contentType: draft.bodyHTML == nil ? "Text" : "HTML", content: draft.bodyHTML ?? draft.bodyText),
            toRecipients: draft.to.map { .init(emailAddress: .init(address: $0)) },
            ccRecipients: draft.cc.map { .init(emailAddress: .init(address: $0)) }
        )

        let _: GraphMessage = try await request(url: url, method: "POST", body: body, token: session.accessToken)
    }

    func deleteMessage(session: MailSession, id: String) async throws {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages/\(id)")!
        try await requestVoid(url: url, method: "DELETE", body: Optional<Data>.none, token: session.accessToken)
    }

    func markRead(session: MailSession, id: String) async throws {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages/\(id)")!
        let body = ["isRead": true]
        let _: GraphMessage = try await request(url: url, method: "PATCH", body: body, token: session.accessToken)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { ASPresentationAnchor() }

    private func oauthValue(key: String) throws -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing \(key)"])
        }
        return value
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
            URLQueryItem(name: "scope", value: "Mail.ReadWrite Mail.Send offline_access")
        ]

        request.httpBody = fields.map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

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
            throw NSError(domain: "OutlookProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Graph request failed"])
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
