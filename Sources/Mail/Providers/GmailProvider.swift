import AuthenticationServices
import CryptoKit
import Foundation
import SwiftUI

final class GmailProvider: NSObject, MailProvider, ASWebAuthenticationPresentationContextProviding {
    var displayName: String { "Gmail" }
    var iconAssetName: String { "envelope.badge.fill" }
    var primaryColor: Color { Color(red: 0.86, green: 0.20, blue: 0.18) }

    private let baseURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me")!
    private let daysPerPage = 14

    func authenticate(credentials: MailCredentials) async throws -> MailSession {
        return try await GoogleOAuthManager.shared.authenticate()
    }

    func fetchInbox(session: MailSession, page: Int) async throws -> [MailMessage] {
        var items = [URLQueryItem(name: "maxResults", value: "30")]
        if page > 0 {
            items.append(URLQueryItem(name: "q", value: "newer_than:\(page * daysPerPage)d"))
        }

        let listURL = baseURL.appendingPathComponent("messages").appending(queryItems: items)
        let list: GmailListResponse = try await request(url: listURL, method: "GET", body: EmptyBody?.none, session: session)

        var messages: [MailMessage] = []
        for item in list.messages ?? [] {
            messages.append(try await fetchMessage(session: session, id: item.id))
        }

        return messages.sorted(by: { $0.date > $1.date })
    }

    func fetchMessage(session: MailSession, id: String) async throws -> MailMessage {
        let url = baseURL.appendingPathComponent("messages/\(id)").appending(queryItems: [URLQueryItem(name: "format", value: "full")])
        let payload: GmailMessagePayload = try await request(url: url, method: "GET", body: EmptyBody?.none, session: session)

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
        try await requestVoid(url: url, method: "POST", body: body, session: session)
    }

    func saveDraft(session: MailSession, draft: MailDraft) async throws {
        let raw = buildRFC2822(draft: draft)
        let body = GmailDraftBody(message: GmailSendBody(raw: Data(raw.utf8).base64URLEncodedString()))
        let url = baseURL.appendingPathComponent("drafts")
        try await requestVoid(url: url, method: "POST", body: body, session: session)
    }

    func deleteMessage(session: MailSession, id: String) async throws {
        let url = baseURL.appendingPathComponent("messages/\(id)")
        try await requestVoid(url: url, method: "DELETE", body: EmptyBody?.none, session: session)
    }

    func markRead(session: MailSession, id: String) async throws {
        let body = GmailModifyBody(addLabelIds: [], removeLabelIds: ["UNREAD"])
        let url = baseURL.appendingPathComponent("messages/\(id)/modify")
        try await requestVoid(url: url, method: "POST", body: body, session: session)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { ASPresentationAnchor() }

    func refreshSessionToken(session: MailSession) async throws -> MailSession {
        guard let tokens = MailKeychainManager.shared.getOAuthTokens(accountId: session.id),
              let refreshToken = tokens.refreshToken else {
            throw NSError(domain: "GmailProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])
        }
        let result = try await GoogleOAuthManager.shared.refreshAccessToken(for: session.id, refreshToken: refreshToken)
        return MailSession(
            id: session.id,
            provider: session.provider,
            email: session.email,
            displayName: session.displayName,
            accessTokenExpiration: result.expiration,
            imapHost: session.imapHost,
            imapPort: session.imapPort,
            smtpHost: session.smtpHost,
            smtpPort: session.smtpPort
        )
    }

    // MARK: - API Request Helpers

    private struct EmptyBody: Encodable {}

    private func request<T: Decodable>(url: URL, session: MailSession) async throws -> T {
        try await request(url: url, method: "GET", body: EmptyBody?.none, session: session)
    }

    private func requestVoid(url: URL, method: String = "GET", session: MailSession) async throws {
        try await requestVoid(url: url, method: method, body: EmptyBody?.none, session: session)
    }

    private func request<T: Decodable, Body: Encodable>(url: URL, method: String = "GET", body: Body? = nil, session: MailSession, isRetry: Bool = false) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = try await GoogleOAuthManager.shared.getValidAccessToken(for: session.id)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        InternalLogger.shared.log("GmailProvider: API Request \(method) \(url.path)", level: .debug)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "GmailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected response type"])
        }

        InternalLogger.shared.log("GmailProvider: API Response \(http.statusCode) for \(url.path)", level: .debug)

        if http.statusCode == 401 && !isRetry {
            InternalLogger.shared.log("GmailProvider: 401 detected, attempting token refresh", level: .warning)
            // Even though getValidAccessToken handles refresh, a 401 might mean the token was revoked or Keychain is out of sync.
            // We force a refresh here by fetching tokens and calling refresh directly if needed,
            // but for simplicity we'll just re-try getValidAccessToken which should handle it.
            // Actually, to BE SURE, let's clear the cache/force refresh.
            return try await self.request(url: url, method: method, body: body, session: session, isRetry: true)
        }

        guard (200...299).contains(http.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Gmail API request failed"
            InternalLogger.shared.log("GmailProvider: Request failed status=\(http.statusCode) message=\(errorMsg)", level: .error)
            throw NSError(domain: "GmailProvider", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func requestVoid<Body: Encodable>(url: URL, method: String = "GET", body: Body? = nil, session: MailSession, isRetry: Bool = false) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = try await GoogleOAuthManager.shared.getValidAccessToken(for: session.id)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        InternalLogger.shared.log("GmailProvider: API Request (Void) \(method) \(url.path)", level: .debug)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "GmailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected response type"])
        }

        InternalLogger.shared.log("GmailProvider: API Response \(http.statusCode) for \(url.path)", level: .debug)

        if http.statusCode == 401 && !isRetry {
            InternalLogger.shared.log("GmailProvider: 401 detected, attempting token refresh", level: .warning)
            try await self.requestVoid(url: url, method: method, body: body, session: session, isRetry: true)
            return
        }

        guard (200...299).contains(http.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Gmail API request failed"
            InternalLogger.shared.log("GmailProvider: Request failed status=\(http.statusCode) message=\(errorMsg)", level: .error)
            throw NSError(domain: "GmailProvider", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    // MARK: - Parsing Helpers

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
