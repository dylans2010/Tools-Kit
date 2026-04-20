import Foundation
import Network
import SwiftUI

final class ProtonMailProvider: MailProvider {
    var displayName: String { "Proton Mail" }
    var iconAssetName: String { "lock.shield" }
    var primaryColor: Color { Color(red: 0.14, green: 0.48, blue: 0.36) }

    let setupGuide = "Install Proton Bridge and sign in before connecting. Proton Bridge must run locally and expose IMAP at 127.0.0.1:1143 and SMTP at 127.0.0.1:1025."

    private let bridgeHost = "127.0.0.1"
    private let bridgeIMAPPort: UInt16 = 1143
    private let bridgeSMTPPort: UInt16 = 1025

    func authenticate(credentials: MailCredentials) async throws -> MailSession {
        guard let password = credentials.password else {
            throw NSError(domain: "ProtonProvider", code: 400, userInfo: [NSLocalizedDescriptionKey: "Bridge password required"])
        }

        var context = try await connect(host: bridgeHost, port: bridgeIMAPPort)
        defer { context.connection.cancel() }

        _ = try await receive(context.connection)
        _ = try await command(context: &context, value: "LOGIN \(quoted(credentials.email)) \(quoted(password))")
        _ = try await command(context: &context, value: "SELECT INBOX")

        return MailSession(
            provider: .proton,
            email: credentials.email,
            displayName: "Proton Mail",
            imapHost: bridgeHost,
            imapPort: bridgeIMAPPort,
            smtpHost: bridgeHost,
            smtpPort: bridgeSMTPPort
        )
    }

    func fetchInbox(session: MailSession, page: Int) async throws -> [MailMessage] {
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else {
            throw NSError(domain: "ProtonProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing bridge credentials"])
        }

        var context = try await connect(host: bridgeHost, port: bridgeIMAPPort)
        defer { context.connection.cancel() }

        _ = try await receive(context.connection)
        _ = try await command(context: &context, value: "LOGIN \(quoted(session.email)) \(quoted(password))")
        _ = try await command(context: &context, value: "SELECT INBOX")

        let search = try await command(context: &context, value: "UID SEARCH ALL")
        let uids = parseUIDSearch(search).sorted()

        let pageSize = 30
        let upper = max(0, uids.count - (page * pageSize))
        let lower = max(0, upper - pageSize)
        guard lower < upper else { return [] }

        let pageUIDs = Array(uids[lower..<upper]).reversed().map(String.init).joined(separator: ",")
        let fetch = try await command(context: &context, value: "UID FETCH \(pageUIDs) (UID ENVELOPE INTERNALDATE BODY.PEEK[TEXT])")
        return parseEnvelopeMessages(fetch)
    }

    func fetchMessage(session: MailSession, id: String) async throws -> MailMessage {
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else {
            throw NSError(domain: "ProtonProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing bridge credentials"])
        }

        var context = try await connect(host: bridgeHost, port: bridgeIMAPPort)
        defer { context.connection.cancel() }

        _ = try await receive(context.connection)
        _ = try await command(context: &context, value: "LOGIN \(quoted(session.email)) \(quoted(password))")
        _ = try await command(context: &context, value: "SELECT INBOX")
        let fetch = try await command(context: &context, value: "UID FETCH \(id) (UID ENVELOPE INTERNALDATE BODY.PEEK[])")

        if let message = parseEnvelopeMessages(fetch).first {
            return message
        }
        throw NSError(domain: "ProtonProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "Message not found"])
    }

    func sendMessage(session: MailSession, draft: MailDraft) async throws {
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else {
            throw NSError(domain: "ProtonProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing bridge credentials"])
        }

        try await SMTPSender.send(
            draft: draft,
            config: SMTPConfig(host: bridgeHost, port: bridgeSMTPPort, username: session.email, password: password, useTLS: false)
        )
    }

    func saveDraft(session: MailSession, draft: MailDraft) async throws {
        // Save as IMAP draft through APPEND on local bridge mailbox.
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else { return }
        var context = try await connect(host: bridgeHost, port: bridgeIMAPPort)
        defer { context.connection.cancel() }

        _ = try await receive(context.connection)
        _ = try await command(context: &context, value: "LOGIN \(quoted(session.email)) \(quoted(password))")

        let raw = [
            "From: \(draft.from)",
            "To: \(draft.to.joined(separator: ", "))",
            draft.cc.isEmpty ? nil : "Cc: \(draft.cc.joined(separator: ", "))",
            draft.bcc.isEmpty ? nil : "Bcc: \(draft.bcc.joined(separator: ", "))",
            "Subject: \(draft.subject)",
            "MIME-Version: 1.0",
            "Content-Type: text/plain; charset=utf-8",
            "",
            draft.bodyText
        ].compactMap { $0 }.joined(separator: "\r\n")
        let literalSize = Data(raw.utf8).count
        _ = try await command(context: &context, value: "APPEND Drafts {\(literalSize)}")
        try await send(context.connection, "\(raw)\r\n")
    }

    func deleteMessage(session: MailSession, id: String) async throws {
        try await flagAndMaybeExpunge(session: session, id: id, delete: true)
    }

    func markRead(session: MailSession, id: String) async throws {
        try await flagAndMaybeExpunge(session: session, id: id, delete: false)
    }

    func unreadCount(session: MailSession) async throws -> Int {
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else { return 0 }
        var context = try await connect(host: bridgeHost, port: bridgeIMAPPort)
        defer { context.connection.cancel() }

        _ = try await receive(context.connection)
        _ = try await command(context: &context, value: "LOGIN \(quoted(session.email)) \(quoted(password))")
        _ = try await command(context: &context, value: "SELECT INBOX")
        let unseen = try await command(context: &context, value: "SEARCH UNSEEN")
        return parseUIDSearch(unseen).count
    }

    private func flagAndMaybeExpunge(session: MailSession, id: String, delete: Bool) async throws {
        guard let password = MailKeychainManager.shared.getPassword(for: session.email) else { return }
        var context = try await connect(host: bridgeHost, port: bridgeIMAPPort)
        defer { context.connection.cancel() }

        _ = try await receive(context.connection)
        _ = try await command(context: &context, value: "LOGIN \(quoted(session.email)) \(quoted(password))")
        _ = try await command(context: &context, value: "SELECT INBOX")

        if delete {
            _ = try await command(context: &context, value: "UID STORE \(id) +FLAGS.SILENT (\\Deleted)")
            _ = try await command(context: &context, value: "EXPUNGE")
        } else {
            _ = try await command(context: &context, value: "UID STORE \(id) +FLAGS.SILENT (\\Seen)")
        }
    }

    private struct Context {
        let connection: NWConnection
        var tag: Int
    }

    private func connect(host: String, port: UInt16) async throws -> Context {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port))
        let connection = NWConnection(to: endpoint, using: .tcp)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready: continuation.resume()
                case .failed(let error): continuation.resume(throwing: error)
                default: break
                }
            }
            connection.start(queue: .global())
        }

        return Context(connection: connection, tag: 1)
    }

    private func command(context: inout Context, value: String) async throws -> String {
        let tag = "A\(context.tag)"
        context.tag += 1
        try await send(context.connection, "\(tag) \(value)\r\n")

        var response = ""
        while true {
            let chunk = try await receive(context.connection)
            response += chunk
            if chunk.contains("\r\n\(tag) ") || chunk.hasPrefix("\(tag) ") {
                if chunk.contains(" NO ") || chunk.contains(" BAD ") {
                    throw NSError(domain: "ProtonProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: response])
                }
                return response
            }
        }
    }

    private func receive(_ connection: NWConnection) async throws -> String {
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
                    continuation.resume(throwing: NSError(domain: "ProtonProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection closed"]))
                } else {
                    continuation.resume(throwing: NSError(domain: "ProtonProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response"]))
                }
            }
        }

        return String(decoding: data, as: UTF8.self)
    }

    private func send(_ connection: NWConnection, _ command: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: Data(command.utf8), completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private func parseUIDSearch(_ response: String) -> [Int] {
        let lines = response.split(whereSeparator: \.isNewline)
        for line in lines where line.hasPrefix("* SEARCH") {
            return line.replacingOccurrences(of: "* SEARCH", with: "")
                .split(separator: " ")
                .compactMap { Int($0) }
        }
        return []
    }

    private func parseEnvelopeMessages(_ response: String) -> [MailMessage] {
        let blocks = response.components(separatedBy: "* ").filter { $0.contains(" FETCH") }
        return blocks.compactMap { block in
            let uid = firstMatch(#"UID\s+(\d+)"#, in: block) ?? UUID().uuidString
            let rawDate = firstMatch(#"DATE\s+"([^"]+)""#, in: block)
            let fromMailbox = firstMatch(#"FROM\s+\(\("[^"]*"\s+NIL\s+"([^"]+)"\s+"([^"]+)"\)\)"#, in: block)
            let subject = firstMatch(#"SUBJECT\s+"([^"]*)""#, in: block) ?? "No Subject"
            let internalDate = firstMatch(#"INTERNALDATE\s+"([^"]+)""#, in: block)
            let body = firstMatch(#"BODY\.PEEK\[[^\]]*\]\s+\{\d+\}\s+([\s\S]*)"#, in: block) ?? ""

            let date = parseDate(rawDate ?? internalDate)
            let from = fromMailbox?.replacingOccurrences(of: "\"", with: "") ?? "Unknown"

            return MailMessage(
                id: uid,
                threadId: "uid-\(uid)",
                from: from,
                to: [],
                cc: [],
                bcc: [],
                subject: MailContentDecoder.decodeEncodedWords(subject),
                body: body.trimmingCharacters(in: .whitespacesAndNewlines),
                htmlBody: nil,
                date: date,
                isRead: false,
                isStarred: false,
                attachments: []
            )
        }
    }

    private func parseDate(_ value: String?) -> Date {
        guard let value else { return Date() }
        let formatters: [DateFormatter] = {
            let one = DateFormatter()
            one.locale = Locale(identifier: "en_US_POSIX")
            one.dateFormat = "dd-MMM-yyyy HH:mm:ss Z"

            let two = DateFormatter()
            two.locale = Locale(identifier: "en_US_POSIX")
            two.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"

            return [one, two]
        }()

        for formatter in formatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return Date()
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
