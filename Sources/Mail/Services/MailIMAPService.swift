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
        let response = try await sendCommand("FETCH 1:50 (FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODY[TEXT])")
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
        let lines = response.components(separatedBy: "\r\n")

        var currentMessage: [String: String] = [:]

        for line in lines {
            if line.contains("FETCH") && line.contains("ENVELOPE") {
                // Extract Subject
                if let subjectRange = line.range(of: "ENVELOPE \\(\"[^\"]*\" \"([^\"]*)\"", options: .regularExpression) {
                    let subject = String(line[subjectRange].dropFirst(12).dropLast(1))
                    currentMessage["subject"] = subject
                }

                // Extract From
                if let fromRange = line.range(of: "(\"[^\"]*\" \"[^\"]*\")", options: .regularExpression) {
                    let from = String(line[fromRange].dropFirst(1).dropLast(1))
                    currentMessage["from"] = from
                }
            }

            if line.contains("BODY[TEXT]") {
                // Simple snippet extraction
                let snippet = line.components(separatedBy: "BODY[TEXT]")[1].trimmingCharacters(in: .whitespacesAndNewlines).prefix(100)
                currentMessage["snippet"] = String(snippet)
            }

            if line.contains(")") && !currentMessage.isEmpty {
                let msg = MailMessage(
                    id: UUID().uuidString,
                    threadId: UUID().uuidString,
                    from: currentMessage["from"] ?? "Unknown",
                    to: ["me@icloud.com"],
                    cc: [],
                    bcc: [],
                    subject: currentMessage["subject"] ?? "No Subject",
                    body: currentMessage["snippet"] ?? "",
                    htmlBody: nil,
                    date: Date(),
                    isRead: false,
                    isStarred: false,
                    attachments: []
                )
                messages.append(msg)
                currentMessage = [:]
            }
        }

        return messages
    }

    func disconnect() {
        connection?.cancel()
    }
}
