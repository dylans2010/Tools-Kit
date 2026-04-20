import Foundation

class GmailMailProvider: MailProviderProtocol {
    let account: MailAccount
    private var accessToken: String?
    private var refreshToken: String?
    private var pageTokensByOffset: [Int: String?] = [0: nil]
    private let baseURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me")!

    init(account: MailAccount) {
        self.account = account
        self.accessToken = account.accessToken
        self.refreshToken = account.refreshToken

        if self.accessToken == nil {
            let stored = MailKeychainManager.shared.getOAuthTokens(accountId: account.id)
            self.accessToken = stored?.accessToken
            self.refreshToken = stored?.refreshToken ?? account.refreshToken
        }
    }

    func fetchFolders() async throws -> [MailFolder] {
        [.inbox, .sent, .drafts, .starred, .trash]
    }

    func fetchThreads(in folder: MailFolder, limit: Int, offset: Int) async throws -> [MailThread] {
        if folder.type != .inbox {
            let query: String
            switch folder.type {
            case .sent: query = "in:sent"
            case .drafts: query = "in:drafts"
            case .starred: query = "is:starred"
            case .trash: query = "in:trash"
            default: query = ""
            }
            return try await searchEmails(query: query, limit: limit)
        }

        let result = try await fetchInbox(limit: limit, offset: offset)
        return result.threads
    }

    func fetchInbox(limit: Int = 50, offset: Int = 0) async throws -> (threads: [MailThread], nextOffset: Int?) {
        InternalLogger.shared.log("GmailMailProvider: fetching inbox for \(account.emailAddress) offset=\(offset) limit=\(limit)", level: .info)

        let pageToken = pageTokensByOffset[offset] ?? nil
        let listURL = try buildListURL(limit: limit, pageToken: pageToken, query: nil)
        let listResponse: GmailInboxPage = try await requestJSON(url: listURL)

        let ids = listResponse.messages?.map { $0.id } ?? []
        var threadsByID: [String: [MailMessage]] = [:]
        for id in ids {
            let message = try await fetchMessage(id: id)
            threadsByID[message.threadId, default: []].append(message)
        }

        let threads = threadsByID.map { (threadId, messages) in
            let ordered = messages.sorted { $0.date < $1.date }
            return MailThread(
                id: threadId,
                subject: ordered.last?.subject ?? "No Subject",
                messages: ordered,
                lastMessageDate: ordered.last?.date ?? Date()
            )
        }
        .sorted(by: { $0.lastMessageDate > $1.lastMessageDate })

        let nextOffset: Int?
        if let nextPage = listResponse.nextPageToken {
            let computed = offset + limit
            pageTokensByOffset[computed] = nextPage
            nextOffset = computed
        } else {
            nextOffset = nil
        }

        InternalLogger.shared.log("GmailMailProvider: fetched \(threads.count) thread(s) for \(account.emailAddress)", level: .debug)
        return (threads: threads, nextOffset: nextOffset)
    }

    func fetchMessage(id: String) async throws -> MailMessage {
        InternalLogger.shared.log("GmailMailProvider: fetching message \(id)", level: .debug)
        let url = baseURL.appendingPathComponent("messages/\(id)")
            .appending(queryItems: [URLQueryItem(name: "format", value: "full")])

        let response: GmailMessageResponse = try await requestJSON(url: url)

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
            attachments: []
        )
    }

    func searchEmails(query: String, limit: Int = 25) async throws -> [MailThread] {
        InternalLogger.shared.log("GmailMailProvider: searching gmail with query='\(query)'", level: .info)
        let listURL = try buildListURL(limit: limit, pageToken: nil, query: query)
        let listResponse: GmailInboxPage = try await requestJSON(url: listURL)

        let ids = listResponse.messages?.map { $0.id } ?? []
        var threadsByID: [String: [MailMessage]] = [:]
        for id in ids {
            let message = try await fetchMessage(id: id)
            threadsByID[message.threadId, default: []].append(message)
        }

        return threadsByID.map { (threadId, messages) in
            let ordered = messages.sorted { $0.date < $1.date }
            return MailThread(
                id: threadId,
                subject: ordered.last?.subject ?? "No Subject",
                messages: ordered,
                lastMessageDate: ordered.last?.date ?? Date()
            )
        }
        .sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
    }

    func sendEmail(to: [String], subject: String, body: String, cc: [String] = [], bcc: [String] = []) async throws {
        let sender = account.emailAddress
        let headers = [
            "From: \(sender)",
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
        .joined(separator: "\r\n")

        guard let rawData = headers.data(using: .utf8) else {
            throw NSError(domain: "GmailMailProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to encode outgoing email"])
        }

        let payload = GmailSendRequest(raw: rawData.gmailBase64URLEncodedString())
        let endpoint = baseURL.appendingPathComponent("messages/send")
        let payloadData = try JSONEncoder().encode(payload)
        let _: GmailEmptyResponse = try await requestJSON(url: endpoint, method: "POST", bodyData: payloadData)
        InternalLogger.shared.log("GmailMailProvider: sent message via Gmail API for \(account.emailAddress)", level: .info)
    }

    func sendMessage(_ message: MailMessage) async throws {
        try await sendEmail(
            to: message.to,
            subject: message.subject,
            body: message.body,
            cc: message.cc,
            bcc: message.bcc
        )
    }

    func markAsRead(_ threadId: String) async throws {
        try await modifyThread(threadId: threadId, add: [], remove: ["UNREAD"])
    }

    func deleteThread(_ threadId: String) async throws {
        let endpoint = baseURL.appendingPathComponent("threads/\(threadId)/trash")
        let emptyBodyData = try JSONEncoder().encode([String: String]())
        let _: GmailEmptyResponse = try await requestJSON(url: endpoint, method: "POST", bodyData: emptyBodyData)
        InternalLogger.shared.log("GmailMailProvider: moved thread \(threadId) to trash", level: .warning)
    }

    func starThread(_ threadId: String, starred: Bool) async throws {
        if starred {
            try await modifyThread(threadId: threadId, add: ["STARRED"], remove: [])
        } else {
            try await modifyThread(threadId: threadId, add: [], remove: ["STARRED"])
        }
    }

    private func modifyThread(threadId: String, add: [String], remove: [String]) async throws {
        let endpoint = baseURL.appendingPathComponent("threads/\(threadId)/modify")
        let body = GmailModifyRequest(addLabelIds: add, removeLabelIds: remove)
        let bodyData = try JSONEncoder().encode(body)
        let _: GmailEmptyResponse = try await requestJSON(url: endpoint, method: "POST", bodyData: bodyData)
        InternalLogger.shared.log("GmailMailProvider: modified labels for thread \(threadId)", level: .debug)
    }

    private func buildListURL(limit: Int, pageToken: String?, query: String?) throws -> URL {
        var items = [URLQueryItem(name: "maxResults", value: String(limit))]
        if let pageToken, !pageToken.isEmpty {
            items.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        if let query, !query.isEmpty {
            items.append(URLQueryItem(name: "q", value: query))
        }

        let url = baseURL.appendingPathComponent("messages").appending(queryItems: items)
        return url
    }

    private func requestJSON<T: Decodable>(url: URL, method: String = "GET", bodyData: Data? = nil) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = try await validAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let bodyData {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "GmailMailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected Gmail response"])
        }

        if http.statusCode == 401 {
            InternalLogger.shared.log("GmailMailProvider: token expired, attempting refresh for \(account.emailAddress)", level: .warning)
            try await refreshAccessToken()
            return try await requestJSON(url: url, method: method, bodyData: bodyData)
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown Gmail API error"
            InternalLogger.shared.log("GmailMailProvider: Gmail API failed status=\(http.statusCode) message=\(message)", level: .error)
            throw NSError(domain: "GmailMailProvider", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        if T.self == GmailEmptyResponse.self {
            return GmailEmptyResponse() as! T
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func validAccessToken() async throws -> String {
        if let accessToken, !accessToken.isEmpty {
            return accessToken
        }

        if let stored = MailKeychainManager.shared.getOAuthTokens(accountId: account.id) {
            accessToken = stored.accessToken
            refreshToken = stored.refreshToken
            return stored.accessToken
        }

        try await refreshAccessToken()
        guard let accessToken, !accessToken.isEmpty else {
            throw NSError(domain: "GmailMailProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing Gmail OAuth access token"])
        }
        return accessToken
    }

    private func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken, !refreshToken.isEmpty else {
            throw NSError(domain: "GmailMailProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing Gmail refresh token"])
        }

        let clientID = try AppConfig.requiredString("GOOGLE_OAUTH_CLIENT_ID")

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        let bodyString = bodyItems
            .map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "GmailMailProvider", code: 500, userInfo: [NSLocalizedDescriptionKey: "Token refresh failed"])
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unable to refresh Gmail token"
            throw NSError(domain: "GmailMailProvider", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        let refreshed = try JSONDecoder().decode(GmailOAuthTokenResponse.self, from: data)
        accessToken = refreshed.accessToken
        let resolvedRefreshToken = refreshed.refreshToken ?? refreshToken
        self.refreshToken = resolvedRefreshToken

        _ = MailKeychainManager.shared.saveOAuthTokens(
            accountId: account.id,
            accessToken: refreshed.accessToken,
            refreshToken: resolvedRefreshToken
        )
        await MainActor.run {
            MailStore.shared.updateAccountTokens(
                accountId: account.id,
                accessToken: refreshed.accessToken,
                refreshToken: resolvedRefreshToken
            )
        }
        InternalLogger.shared.log("GmailMailProvider: refreshed access token for \(account.emailAddress)", level: .info)
    }

    private func parseAddressList(_ value: String?) -> [String] {
        guard let value, !value.isEmpty else { return [] }
        return value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
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
            domain: "GmailMailProvider",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Missing required OAuth config key \(primaryKey)"]
        )
    }

    private func localConfigValue(forKey key: String) -> String? {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }

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
            return decodeRemoteVariables(from: data)
        } catch {
            return [:]
        }
    }

    private func decodeRemoteVariables(from data: Data) -> [String: String] {
        if let direct = try? JSONDecoder().decode([String: String].self, from: data) {
            return direct
                .mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.value.isEmpty }
        }

        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return [:]
        }

        var values: [String: String] = [:]
        collectRemoteVariables(from: object, into: &values, parentKey: nil)
        return values
            .mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.value.isEmpty }
    }

    private func collectRemoteVariables(from object: Any, into output: inout [String: String], parentKey: String?) {
        switch object {
        case let dictionary as [String: Any]:
            if let key = dictionary["key"] as? String, let value = dictionary["value"] as? String {
                output[key] = value
            }
            if let parentKey, let value = dictionary["value"] as? String, looksLikeConfigKey(parentKey) {
                output[parentKey] = value
            }

            for (key, value) in dictionary {
                if let stringValue = value as? String, looksLikeConfigKey(key) {
                    output[key] = stringValue
                }
                collectRemoteVariables(from: value, into: &output, parentKey: key)
            }
        case let array as [Any]:
            for item in array {
                collectRemoteVariables(from: item, into: &output, parentKey: parentKey)
            }
        default:
            break
        }
    }

    private func looksLikeConfigKey(_ key: String) -> Bool {
        guard key.range(of: #"^[A-Z][A-Z0-9_]*$"#, options: .regularExpression) != nil else { return false }
        let allowedPrefixes = ["APPWRITE_", "GOOGLE_", "GMAIL_", "PRODUCTION_", "DAILY_", "MAIL_", "OUTLOOK_", "YAHOO_"]
        return allowedPrefixes.contains { key.hasPrefix($0) }
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

}
