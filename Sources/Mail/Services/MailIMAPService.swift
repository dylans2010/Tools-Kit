import Foundation
import Network

class MailIMAPService: @unchecked Sendable {
    private let host: String = "imap.mail.me.com"
    private let port: UInt16 = 993
    private var connection: NWConnection?
    private var tagCounter = 1

    func connect() async throws {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port))
        let parameters = NWParameters.tls
        connection = NWConnection(to: endpoint, using: parameters)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            connection?.start(queue: .global())
        }
    }

    func login(user: String, pass: String) async throws {
        _ = try await sendCommand("LOGIN \(user) \(pass)")
    }

    func fetchThreads(account: MailAccount, folder: MailFolder, password: String, limit: Int, offset: Int) async throws -> [MailThread] {
        try await connect()
        try await login(user: account.email, pass: password)
        let messages = try await fetchMessages(folder: folder.id, limit: limit, offset: offset)
        disconnect()

        let grouped = Dictionary(grouping: messages, by: { $0.threadId })
        let threads = grouped.map { (_, msgs) in
            MailThread(
                id: msgs.first?.threadId ?? UUID().uuidString,
                subject: msgs.first?.subject ?? "No Subject",
                messages: msgs.sorted(by: { $0.date < $1.date }),
                lastMessageDate: msgs.map(\.date).max() ?? Date()
            )
        }

        return threads.sorted(by: { $0.lastMessageDate > $1.lastMessageDate })
    }

    func fetchMessages(folder: String, limit: Int, offset: Int) async throws -> [MailMessage] {
        _ = try await sendCommand("SELECT \(folder)")
        let start = max(1, offset + 1)
        let end = offset + limit
        let response = try await sendCommand("UID FETCH \(start):\(end) (UID FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODY[])")
        return parseMessages(response)
    }

    private func sendCommand(_ command: String) async throws -> String {
        let tag = "A\(tagCounter)"
        tagCounter += 1
        let fullCommand = "\(tag) \(command)\r\n"

        return try await withCheckedThrowingContinuation { continuation in
            connection?.send(content: fullCommand.data(using: .utf8), completion: .contentProcessed({ error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                self.connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let data = data, let response = String(data: data, encoding: .utf8) {
                        continuation.resume(returning: response)
                    } else {
                        continuation.resume(throwing: NSError(domain: "IMAPError", code: -1, userInfo: nil))
                    }
                }
            }))
        }
    }

    private func parseMessages(_ response: String) -> [MailMessage] {
        var messages: [MailMessage] = []

        // Split on FETCH response boundaries
        let fetchPattern = #"\* \d+ FETCH"#
        guard let regex = try? NSRegularExpression(pattern: fetchPattern) else { return messages }

        let nsResponse = response as NSString
        let matches = regex.matches(in: response, range: NSRange(location: 0, length: nsResponse.length))

        for (index, match) in matches.enumerated() {
            let start = match.range.location
            let end = index + 1 < matches.count ? matches[index + 1].range.location : nsResponse.length
            let fetchBlock = nsResponse.substring(with: NSRange(location: start, length: end - start))

            // Extract ENVELOPE fields
            let subject = MailContentDecoder.decodeEncodedWords(extractEnvelopeField(fetchBlock, field: "subject") ?? "No Subject")
            let from = MailContentDecoder.decodeEncodedWords(extractEnvelopeFrom(fetchBlock) ?? "Unknown")
            let uid = extractUID(fetchBlock) ?? UUID().uuidString
            let date = extractInternalDate(fetchBlock) ?? Date()

            // Extract raw BODY[] content and run through MIME pipeline
            let rawBody = extractBodyContent(fetchBlock)
            let parsed = MailMIMEParser.parse(rawBody)
            let rendered = MailContentRenderer.render(from: parsed)

            let msg = MailMessage(
                id: uid,
                threadId: subject, // basic thread grouping by subject for now
                from: from,
                to: ["me@icloud.com"],
                cc: [],
                bcc: [],
                subject: subject,
                body: rendered.plainBody ?? "",
                htmlBody: rendered.htmlBody,
                date: date,
                isRead: false,
                isStarred: false,
                attachments: []
            )
            messages.append(msg)
        }

        return messages
    }

    // MARK: - Response Parsing Helpers

    private func extractBodyContent(_ fetchBlock: String) -> String {
        // Match BODY[] {size}\r\n<content> or BODY[] "content"
        let literalPattern = #"BODY\[\]\s*\{(\d+)\}\r?\n([\s\S]*)"#
        if let regex = try? NSRegularExpression(pattern: literalPattern),
           let match = regex.firstMatch(in: fetchBlock, range: NSRange(fetchBlock.startIndex..., in: fetchBlock)),
           let sizeRange = Range(match.range(at: 1), in: fetchBlock),
           let bodyRange = Range(match.range(at: 2), in: fetchBlock) {
            let size = Int(fetchBlock[sizeRange]) ?? 0
            let body = String(fetchBlock[bodyRange])
            // Trim to the declared literal size (in bytes)
            if let data = body.data(using: .utf8) {
                let clipped = data.prefix(size)
                return String(data: clipped, encoding: .utf8) ?? body
            }
            return body
        }

        // Fallback: grab everything after BODY[]
        if let range = fetchBlock.range(of: "BODY[]") {
            return String(fetchBlock[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ""
    }

    private func extractUID(_ block: String) -> String? {
        let uidPattern = #"UID (\d+)"#
        if let regex = try? NSRegularExpression(pattern: uidPattern),
           let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
           let range = Range(match.range(at: 1), in: block) {
            return String(block[range])
        }
        return nil
    }

    private func extractInternalDate(_ block: String) -> Date? {
        let datePattern = #"INTERNALDATE \"([^\"]+)\""#
        guard
            let regex = try? NSRegularExpression(pattern: datePattern),
            let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
            let range = Range(match.range(at: 1), in: block)
        else { return nil }

        let dateString = String(block[range])
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd-MMM-yyyy HH:mm:ss Z"
        return formatter.date(from: dateString)
    }

    private func extractEnvelopeField(_ block: String, field: String) -> String? {
        // Very simplified ENVELOPE subject extraction
        // ENVELOPE ( "date" "subject" (("name" NIL "user" "domain")) ...
        guard let envRange = block.range(of: "ENVELOPE (") else { return nil }
        let envContent = String(block[envRange.upperBound...])

        // Split on space-delimited quoted strings
        var strings: [String] = []
        var inString = false
        var current = ""
        for char in envContent {
            if char == "\"" {
                if inString {
                    strings.append(current)
                    current = ""
                }
                inString.toggle()
            } else if inString {
                current.append(char)
            }
        }

        // ENVELOPE position 2 (0-indexed) is the subject
        switch field {
        case "subject": return strings.count > 1 ? strings[1] : nil
        default:        return nil
        }
    }

    private func extractEnvelopeFrom(_ block: String) -> String? {
        // Grab the email address from the FROM structure inside ENVELOPE
        // FROM is at position 3: (("personal" NIL "mailbox" "host"))
        let fromPattern = #"\(\("([^"]*)" NIL "([^"]*)" "([^"]*)"\)\)"#
        if let regex = try? NSRegularExpression(pattern: fromPattern),
           let match = regex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)) {
            let name    = (Range(match.range(at: 1), in: block)).map { String(block[$0]) } ?? ""
            let mailbox = (Range(match.range(at: 2), in: block)).map { String(block[$0]) } ?? ""
            let host    = (Range(match.range(at: 3), in: block)).map { String(block[$0]) } ?? ""
            if !mailbox.isEmpty && !host.isEmpty {
                return name.isEmpty ? "\(mailbox)@\(host)" : "\(name) <\(mailbox)@\(host)>"
            }
        }
        return nil
    }

    func disconnect() {
        connection?.cancel()
    }
}
