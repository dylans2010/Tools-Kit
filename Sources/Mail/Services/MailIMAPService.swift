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

    func fetchMessages(folder: String) async throws -> [MailMessage] {
        _ = try await sendCommand("SELECT \(folder)")
        // Fetch full RFC822 body so MIME parsing works correctly
        let response = try await sendCommand("FETCH 1:50 (FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODY[])")
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
            let subject = extractEnvelopeField(fetchBlock, field: "subject") ?? "No Subject"
            let from = extractEnvelopeFrom(fetchBlock) ?? "Unknown"

            // Extract raw BODY[] content and run through MIME pipeline
            let rawBody = extractBodyContent(fetchBlock)
            let (htmlBody, plainBody) = decodeMIME(rawBody)

            let msg = MailMessage(
                id: UUID().uuidString,
                threadId: UUID().uuidString,
                from: MailContentDecoder.decodeEncodedWords(from),
                to: ["me@icloud.com"],
                cc: [],
                bcc: [],
                subject: MailContentDecoder.decodeEncodedWords(subject),
                body: plainBody,
                htmlBody: htmlBody,
                date: Date(),
                isRead: false,
                isStarred: false,
                attachments: []
            )
            messages.append(msg)
        }

        return messages
    }

    // MARK: - MIME Pipeline

    /// Parse raw IMAP body through MailMIMEParser → MailContentDecoder.
    /// Returns (htmlBody, plainBody). At least one will be non-nil.
    private func decodeMIME(_ raw: String) -> (String?, String) {
        guard !raw.isEmpty else { return (nil, "") }

        let parsed = MailMIMEParser.parse(raw)

        let html: String?
        if let htmlPart = parsed.htmlPart {
            let decoded = MailContentDecoder.decode(htmlPart.content, transferEncoding: htmlPart.transferEncoding)
            html = decoded.isEmpty ? nil : decoded
        } else {
            html = nil
        }

        let plain: String
        if let textPart = parsed.textPart {
            plain = MailContentDecoder.decode(textPart.content, transferEncoding: textPart.transferEncoding)
        } else if html == nil {
            // No MIME structure: treat the raw content as plain text
            plain = MailContentDecoder.decodeQuotedPrintable(raw)
        } else {
            plain = ""
        }

        return (html, plain)
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
