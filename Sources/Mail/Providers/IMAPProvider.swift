import Foundation
import Network
import SwiftUI

final class IMAPProvider: MailProvider {
    var displayName: String { "IMAP / Other" }
    var iconAssetName: String { "server.rack" }
    var primaryColor: Color { Color(red: 0.47, green: 0.52, blue: 0.61) }

    private struct IMAPConnectionContext: Sendable {
        let connection: NWConnection
        var tagCounter: Int
    }

    func authenticate(credentials: MailCredentials) async throws -> MailSession {
        guard let host = credentials.host, let port = credentials.port, let password = credentials.password else {
            throw NSError(domain: "IMAPProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "Host, port, and password are required"])
        }

        var context = try await connect(host: host, port: port, tls: true)
        defer { context.connection.cancel() }

        _ = try await readResponse(connection: context.connection)
        _ = try await sendCommand(context: &context, command: "LOGIN \(quoted(credentials.email)) \(quoted(password))")
        _ = try await sendCommand(context: &context, command: "SELECT INBOX")

        return MailSession(
            id: UUID().uuidString,
            provider: .imap,
            email: credentials.email,
            displayName: credentials.email,
            accessTokenExpiration: nil,
            imapHost: host,
            imapPort: port,
            smtpHost: credentials.smtpHost,
            smtpPort: credentials.smtpPort
        )
    }

    func fetchInbox(session: MailSession, page: Int) async throws -> [MailMessage] {
        guard let host = session.imapHost, let port = session.imapPort else {
            throw NSError(domain: "IMAPProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "IMAP host not configured"])
        }
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else {
            throw NSError(domain: "IMAPProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])
        }

        var context = try await connect(host: host, port: port, tls: true)
        defer { context.connection.cancel() }

        _ = try await readResponse(connection: context.connection)
        _ = try await sendCommand(context: &context, command: "LOGIN \(quoted(session.email)) \(quoted(password))")
        _ = try await sendCommand(context: &context, command: "SELECT INBOX")

        let search = try await sendCommand(context: &context, command: "UID SEARCH ALL")
        let allUIDs = parseUIDSearch(search).sorted()

        let pageSize = 30
        let upper = max(0, allUIDs.count - (page * pageSize))
        let lower = max(0, upper - pageSize)
        guard lower < upper else { return [] }

        let pageUIDs = Array(allUIDs[lower..<upper]).reversed().map(String.init).joined(separator: ",")
        let fetch = try await sendCommand(context: &context, command: "UID FETCH \(pageUIDs) (UID FLAGS INTERNALDATE ENVELOPE BODY.PEEK[TEXT])")

        return parseFetchMessages(fetch)
    }

    func fetchMessage(session: MailSession, id: String) async throws -> MailMessage {
        guard let host = session.imapHost, let port = session.imapPort else {
            throw NSError(domain: "IMAPProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "IMAP host not configured"])
        }
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else {
            throw NSError(domain: "IMAPProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])
        }

        var context = try await connect(host: host, port: port, tls: true)
        defer { context.connection.cancel() }

        _ = try await readResponse(connection: context.connection)
        _ = try await sendCommand(context: &context, command: "LOGIN \(quoted(session.email)) \(quoted(password))")
        _ = try await sendCommand(context: &context, command: "SELECT INBOX")

        let response = try await sendCommand(context: &context, command: "UID FETCH \(id) (UID FLAGS INTERNALDATE ENVELOPE BODY.PEEK[])")
        if let message = parseFetchMessages(response).first {
            return message
        }
        throw NSError(domain: "IMAPProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "Message not found"])
    }

    func sendMessage(session: MailSession, draft: MailDraft) async throws {
        guard let smtpHost = session.smtpHost, let smtpPort = session.smtpPort else {
            throw NSError(domain: "IMAPProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "SMTP settings are required"])
        }
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else {
            throw NSError(domain: "IMAPProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])
        }

        try await SMTPSender.send(
            draft: draft,
            config: SMTPConfig(host: smtpHost, port: smtpPort, username: session.email, password: password, useTLS: true)
        )
    }

    func saveDraft(session: MailSession, draft: MailDraft) async throws {
        guard let host = session.imapHost, let port = session.imapPort else { return }
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else { return }

        var context = try await connect(host: host, port: port, tls: true)
        defer { context.connection.cancel() }
        _ = try await readResponse(connection: context.connection)
        _ = try await sendCommand(context: &context, command: "LOGIN \(quoted(session.email)) \(quoted(password))")

        let raw = "Subject: \(draft.subject)\r\n\r\n\(draft.bodyText)"
        let literalSize = Data(raw.utf8).count
        _ = try await sendCommand(context: &context, command: "APPEND Drafts {\(literalSize)}")
        try await sendRaw(context: &context, raw + "\r\n")
    }

    func deleteMessage(session: MailSession, id: String) async throws {
        try await setFlags(session: session, id: id, flags: "(\\Deleted)")
        _ = try await expunge(session: session)
    }

    func markRead(session: MailSession, id: String) async throws {
        try await setFlags(session: session, id: id, flags: "(\\Seen)")
    }

    func idle(session: MailSession, seconds: UInt64 = 20) async throws {
        guard let host = session.imapHost, let port = session.imapPort else { return }
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else { return }
        var context = try await connect(host: host, port: port, tls: true)
        defer { context.connection.cancel() }

        _ = try await readResponse(connection: context.connection)
        _ = try await sendCommand(context: &context, command: "LOGIN \(quoted(session.email)) \(quoted(password))")
        _ = try await sendCommand(context: &context, command: "SELECT INBOX")
        _ = try await sendCommand(context: &context, command: "IDLE")
        try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
        try await sendRaw(context: &context, "DONE\r\n")
    }

    private func setFlags(session: MailSession, id: String, flags: String) async throws {
        guard let host = session.imapHost, let port = session.imapPort else { return }
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else { return }
        var context = try await connect(host: host, port: port, tls: true)
        defer { context.connection.cancel() }

        _ = try await readResponse(connection: context.connection)
        _ = try await sendCommand(context: &context, command: "LOGIN \(quoted(session.email)) \(quoted(password))")
        _ = try await sendCommand(context: &context, command: "SELECT INBOX")
        _ = try await sendCommand(context: &context, command: "UID STORE \(id) +FLAGS.SILENT \(flags)")
    }

    private func expunge(session: MailSession) async throws -> String {
        guard let host = session.imapHost, let port = session.imapPort else { return "" }
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else { return "" }
        var context = try await connect(host: host, port: port, tls: true)
        defer { context.connection.cancel() }

        _ = try await readResponse(connection: context.connection)
        _ = try await sendCommand(context: &context, command: "LOGIN \(quoted(session.email)) \(quoted(password))")
        _ = try await sendCommand(context: &context, command: "SELECT INBOX")
        return try await sendCommand(context: &context, command: "EXPUNGE")
    }

    private func connect(host: String, port: UInt16, tls: Bool) async throws -> IMAPConnectionContext {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port))
        let parameters: NWParameters = tls ? {
            let params = NWParameters(tls: NWProtocolTLS.Options(), tcp: NWProtocolTCP.Options())
            return params
        }() : .tcp

        let connection = NWConnection(to: endpoint, using: parameters)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            connection.start(queue: .global())
        }

        return IMAPConnectionContext(connection: connection, tagCounter: 1)
    }

    private func sendCommand(context: inout IMAPConnectionContext, command: String) async throws -> String {
        let tag = "A\(context.tagCounter)"
        context.tagCounter += 1
        try await sendRaw(context: &context, "\(tag) \(command)\r\n")

        var collected = ""
        while true {
            let line = try await readResponse(connection: context.connection)
            collected += line
            if line.contains("\r\n\(tag) ") || line.hasPrefix("\(tag) ") {
                if line.contains(" NO ") || line.contains(" BAD ") {
                    throw NSError(domain: "IMAPProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: line])
                }
                return collected
            }
        }
    }

    private func sendRaw(context: inout IMAPConnectionContext, _ string: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.connection.send(content: Data(string.utf8), completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private func readResponse(connection: NWConnection) async throws -> String {
        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 262_144) { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let data, !data.isEmpty {
                    continuation.resume(returning: data)
                    return
                }
                if isComplete {
                    continuation.resume(throwing: NSError(domain: "IMAPProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection closed"]))
                } else {
                    continuation.resume(throwing: NSError(domain: "IMAPProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response"]))
                }
            }
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func parseUIDSearch(_ response: String) -> [Int] {
        var uids: [Int] = []
        let lines = response.split(whereSeparator: \.isNewline).map(String.init)
        for line in lines where line.hasPrefix("* SEARCH") {
            for token in line.replacingOccurrences(of: "* SEARCH", with: "").split(separator: " ") {
                if let uid = Int(token) {
                    uids.append(uid)
                }
            }
        }
        return uids
    }

    private func parseFetchMessages(_ response: String) -> [MailMessage] {
        enum ParserState: Sendable {
            case idle
            case inFetch
        }

        var state: ParserState = .idle
        var currentLines: [String] = []
        var messages: [MailMessage] = []

        let lines = response.split(whereSeparator: \.isNewline).map(String.init)
        for line in lines {
            switch state {
            case .idle:
                if line.hasPrefix("* ") && line.contains(" FETCH ") {
                    state = .inFetch
                    currentLines = [line]
                }
            case .inFetch:
                currentLines.append(line)
                if line == ")" || line.contains("UID ") {
                    if let message = buildMessage(from: currentLines.joined(separator: "\n")) {
                        messages.append(message)
                    }
                    state = .idle
                    currentLines = []
                }
            }
        }

        return messages
    }

    private func buildMessage(from block: String) -> MailMessage? {
        let uid = firstMatch(#"UID\s+(\d+)"#, in: block) ?? UUID().uuidString
        let subject = decodeEncodedWords(firstMatch(#"ENVELOPE\s*\("[^"]*"\s+"([^"]*)""#, in: block) ?? "No Subject")
        let dateString = firstMatch(#"INTERNALDATE\s+"([^"]+)""#, in: block)
        let fromMailbox = firstMatch(#"\("[^"]*"\s+NIL\s+"([^"]+)"\s+"([^"]+)"\)"#, in: block)

        let date = parseIMAPDate(dateString)
        let flags = firstMatch(#"FLAGS\s+\(([^\)]*)\)"#, in: block) ?? ""
        let isRead = flags.contains("\\Seen")
        let isStarred = flags.contains("\\Flagged")
        let body = firstMatch(#"BODY\.PEEK\[[^\]]*\]\s+\{\d+\}\s+([\s\S]*)"#, in: block) ?? ""

        return MailMessage(
            id: uid,
            threadId: "uid-\(uid)",
            from: fromMailbox ?? "Unknown",
            to: [],
            cc: [],
            bcc: [],
            subject: subject,
            body: body.trimmingCharacters(in: .whitespacesAndNewlines),
            htmlBody: nil,
            date: date,
            isRead: isRead,
            isStarred: isStarred,
            attachments: []
        )
    }

    private func decodeEncodedWords(_ value: String) -> String {
        MailContentDecoder.decodeEncodedWords(value)
    }

    private func parseIMAPDate(_ value: String?) -> Date {
        guard let value else { return Date() }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd-MMM-yyyy HH:mm:ss Z"
        return formatter.date(from: value) ?? Date()
    }

    private func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return nil }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: nsRange),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private func quoted(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
