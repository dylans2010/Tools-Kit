import Foundation

enum GmailServiceError: LocalizedError {
    case missingTokens
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingTokens:
            return "Missing Gmail OAuth tokens."
        case .invalidResponse:
            return "Invalid response from Gmail API."
        case .apiError(let message):
            return message
        }
    }
}

final class GmailService: @unchecked Sendable {
    private let tokenStore: GmailTokenStore
    private let accountId: String
    private let baseURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me")!
    private var fallbackAccessToken: String?
    private var fallbackRefreshToken: String?
    private var fallbackEmail: String?

    init(
        accountId: String,
        tokenStore: GmailTokenStore = .shared,
        fallbackAccessToken: String? = nil,
        fallbackRefreshToken: String? = nil,
        fallbackEmail: String? = nil
    ) {
        self.accountId = accountId
        self.tokenStore = tokenStore
        self.fallbackAccessToken = fallbackAccessToken
        self.fallbackRefreshToken = fallbackRefreshToken
        self.fallbackEmail = fallbackEmail
    }

    func fetchInbox(maxResults: Int = 50, pageToken: String? = nil) async throws -> GmailInboxPage {
        var queryItems = [URLQueryItem(name: "maxResults", value: String(maxResults))]
        if let pageToken, !pageToken.isEmpty {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        let url = baseURL.appendingPathComponent("messages").appending(queryItems: queryItems)
        let response: GmailInboxListResponse = try await request(url: url)
        return GmailInboxPage(messages: response.messages ?? [], nextPageToken: response.nextPageToken)
    }

    func fetchMessage(id: String) async throws -> MailMessage {
        let url = baseURL
            .appendingPathComponent("messages/\(id)")
            .appending(queryItems: [URLQueryItem(name: "format", value: "full")])
        let response: GmailMessageResponse = try await request(url: url)

        let headers = response.payload?.flattenedHeaders() ?? [:]
        let from = headers["from"] ?? "Unknown"
        let to = parseAddressList(headers["to"])
        let cc = parseAddressList(headers["cc"])
        let bcc = parseAddressList(headers["bcc"])
        let subject = headers["subject"] ?? "No Subject"
        let date = parseGmailDate(internalDate: response.internalDate, fallback: headers["date"])
        let plainBody = response.payload?.firstBody(for: "text/plain")?.decodedBody() ?? ""
        let htmlBody = response.payload?.firstBody(for: "text/html")?.decodedBody()
        let labels = Set(response.labelIds ?? [])
        let attachments = extractAttachments(from: response.payload)

        return MailMessage(
            id: response.id,
            threadId: response.threadId,
            from: from,
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: plainBody,
            htmlBody: htmlBody,
            date: date,
            isRead: !labels.contains("UNREAD"),
            isStarred: labels.contains("STARRED"),
            attachments: attachments
        )
    }

    func sendEmail(to: [String], subject: String, body: String, cc: [String] = [], bcc: [String] = [], from: String? = nil) async throws {
        let sender = from ?? loadTokens()?.emailAddress ?? ""
        let rawPayload = buildRFC2822(from: sender, to: to, cc: cc, bcc: bcc, subject: subject, body: body)
        let body = GmailSendRequest(raw: Data(rawPayload.utf8).gmailBase64URLEncodedString())
        let url = baseURL.appendingPathComponent("messages/send")
        let _: GmailEmptyResponse = try await request(url: url, method: "POST", body: body)
    }

    func saveDraft(to: [String], subject: String, body: String, cc: [String] = [], bcc: [String] = [], from: String? = nil) async throws {
        let sender = from ?? loadTokens()?.emailAddress ?? ""
        let rawPayload = buildRFC2822(from: sender, to: to, cc: cc, bcc: bcc, subject: subject, body: body)
        let body = GmailDraftRequest(message: GmailSendRequest(raw: Data(rawPayload.utf8).gmailBase64URLEncodedString()))
        let url = baseURL.appendingPathComponent("drafts")
        let _: GmailEmptyResponse = try await request(url: url, method: "POST", body: body)
    }

    func markMessageRead(id: String) async throws {
        let url = baseURL.appendingPathComponent("messages/\(id)/modify")
        let body = GmailModifyRequest(addLabelIds: [], removeLabelIds: ["UNREAD"])
        let _: GmailEmptyResponse = try await request(url: url, method: "POST", body: body)
    }

    func deleteMessage(id: String) async throws {
        let url = baseURL.appendingPathComponent("messages/\(id)")
        let _: GmailEmptyResponse = try await request(url: url, method: "DELETE")
    }

    @discardableResult
    func refreshAccessToken() async throws -> GmailTokenBundle {
        guard let current = loadTokens() else {
            throw GmailServiceError.missingTokens
        }

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let fields = [
            URLQueryItem(name: "client_id", value: GmailModuleConfig.clientID),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: current.refreshToken)
        ]
        request.httpBody = gmailFormURLEncodedBody(fields)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GmailServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unable to refresh Gmail access token."
            throw GmailServiceError.apiError(message)
        }

        let refreshed = try JSONDecoder().decode(GmailOAuthTokenResponse.self, from: data)
        let updated = GmailTokenBundle(
            accessToken: refreshed.accessToken,
            refreshToken: refreshed.refreshToken ?? current.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(refreshed.expiresIn)),
            emailAddress: current.emailAddress
        )
        _ = tokenStore.save(updated, accountId: accountId)
        return updated
    }

    private func request<T: Decodable, Body: Encodable>(url: URL, method: String = "GET", body: Body? = nil, retried: Bool = false) async throws -> T {
        let token = try await validAccessToken()

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GmailServiceError.invalidResponse
        }

        if http.statusCode == 401, !retried {
            _ = try await refreshAccessToken()
            return try await request(url: url, method: method, body: body, retried: true)
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Gmail API request failed."
            throw GmailServiceError.apiError(message)
        }

        if T.self == GmailEmptyResponse.self {
            // Safe because this branch is guarded by an exact runtime type check above.
            return GmailEmptyResponse() as! T
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func validAccessToken() async throws -> String {
        guard let tokens = loadTokens() else {
            throw GmailServiceError.missingTokens
        }

        if tokens.expiresAt.timeIntervalSinceNow < 60 {
            return try await refreshAccessToken().accessToken
        }
        return tokens.accessToken
    }

    private func loadTokens() -> GmailTokenBundle? {
        if let stored = tokenStore.load(accountId: accountId) {
            return stored
        }

        if
            let access = fallbackAccessToken, !access.isEmpty,
            let refresh = fallbackRefreshToken, !refresh.isEmpty
        {
            let fallback = GmailTokenBundle(
                accessToken: access,
                refreshToken: refresh,
                expiresAt: Date().addingTimeInterval(300),
                emailAddress: fallbackEmail ?? ""
            )
            _ = tokenStore.save(fallback, accountId: accountId)
            return fallback
        }

        if let legacy = MailKeychainManager.shared.getOAuthTokens(accountId: accountId), let refresh = legacy.refreshToken, !refresh.isEmpty {
            let migrated = GmailTokenBundle(
                accessToken: legacy.accessToken,
                refreshToken: refresh,
                expiresAt: Date().addingTimeInterval(300),
                emailAddress: fallbackEmail ?? ""
            )
            _ = tokenStore.save(migrated, accountId: accountId)
            return migrated
        }

        return nil
    }

    private func parseAddressList(_ value: String?) -> [String] {
        guard let value, !value.isEmpty else { return [] }
        return value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func parseGmailDate(internalDate: String?, fallback: String?) -> Date {
        if let internalDate, let milliseconds = Double(internalDate) {
            return Date(timeIntervalSince1970: milliseconds / 1000.0)
        }

        guard let fallback else { return Date() }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
        return formatter.date(from: fallback) ?? Date()
    }

    private func buildRFC2822(from: String, to: [String], cc: [String], bcc: [String], subject: String, body: String) -> String {
        let lines = [
            "From: \(from)",
            "To: \(to.joined(separator: ","))",
            cc.isEmpty ? nil : "Cc: \(cc.joined(separator: ","))",
            bcc.isEmpty ? nil : "Bcc: \(bcc.joined(separator: ","))",
            "Subject: \(subject)",
            "MIME-Version: 1.0",
            "Content-Type: text/plain; charset=utf-8",
            "",
            body
        ]
        .compactMap { $0 }

        return lines.joined(separator: "\r\n")
    }

    private func extractAttachments(from payload: GmailPayload?) -> [MailMessage.MailAttachment] {
        guard let payload else { return [] }

        var attachments: [MailMessage.MailAttachment] = []
        var queue: [GmailPayload] = [payload]
        var index = 0

        while !queue.isEmpty {
            let part = queue.removeFirst()
            if let children = part.parts {
                queue.append(contentsOf: children)
            }

            let filename = (part.filename ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !filename.isEmpty else { continue }

            attachments.append(
                MailMessage.MailAttachment(
                    id: "\(filename)-\(index)",
                    fileName: filename,
                    contentType: part.mimeType ?? "application/octet-stream",
                    size: Int64(part.body?.size ?? 0)
                )
            )
            index += 1
        }

        return attachments
    }
}

private struct GmailInboxListResponse: Decodable {
    let messages: [GmailMessageRef]?
    let nextPageToken: String?
}
