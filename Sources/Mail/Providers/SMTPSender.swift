import Foundation
import Network

struct SMTPConfig: Sendable {
    let host: String
    let port: UInt16
    let username: String
    let password: String
    let useTLS: Bool
}

enum SMTPSender {
    static func send(draft: MailDraft, config: SMTPConfig) async throws {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(config.host), port: NWEndpoint.Port(integerLiteral: config.port))
        let parameters: NWParameters = config.useTLS ? .tls : .tcp
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

        _ = try await receiveLine(connection)
        try await expect(connection, command: "EHLO tools-kit.app", accepted: [250])
        try await expect(connection, command: "AUTH LOGIN", accepted: [334])
        try await expect(connection, command: Data(config.username.utf8).base64EncodedString(), accepted: [334])
        try await expect(connection, command: Data(config.password.utf8).base64EncodedString(), accepted: [235])

        try await expect(connection, command: "MAIL FROM:<\(draft.from)>", accepted: [250])
        for address in draft.to + draft.cc + draft.bcc {
            try await expect(connection, command: "RCPT TO:<\(address)>", accepted: [250, 251])
        }

        try await expect(connection, command: "DATA", accepted: [354])
        try await send(connection, data: mimeData(for: draft) + Data("\r\n.\r\n".utf8))
        let done = try await receiveLine(connection)
        guard responseCode(done) == 250 else {
            throw NSError(domain: "SMTPSender", code: -1, userInfo: [NSLocalizedDescriptionKey: done])
        }

        _ = try? await expect(connection, command: "QUIT", accepted: [221])
        connection.cancel()
    }

    private static func mimeData(for draft: MailDraft) -> Data {
        let boundary = "Boundary-\(UUID().uuidString)"
        var lines: [String] = [
            "From: \(draft.from)",
            "To: \(draft.to.joined(separator: \", \"))",
            draft.cc.isEmpty ? nil : "Cc: \(draft.cc.joined(separator: \", \"))",
            draft.bcc.isEmpty ? nil : "Bcc: \(draft.bcc.joined(separator: \", \"))",
            "Subject: \(draft.subject)",
            "Date: \(rfc2822Date(Date()))",
            "MIME-Version: 1.0"
        ].compactMap { $0 }

        if let html = draft.bodyHTML, !html.isEmpty {
            lines.append("Content-Type: multipart/alternative; boundary=\"\(boundary)\"")
            lines.append("")
            lines.append("--\(boundary)")
            lines.append("Content-Type: text/plain; charset=utf-8")
            lines.append("Content-Transfer-Encoding: 8bit")
            lines.append("")
            lines.append(draft.bodyText)
            lines.append("--\(boundary)")
            lines.append("Content-Type: text/html; charset=utf-8")
            lines.append("Content-Transfer-Encoding: 8bit")
            lines.append("")
            lines.append(html)
            lines.append("--\(boundary)--")
        } else {
            lines.append("Content-Type: text/plain; charset=utf-8")
            lines.append("Content-Transfer-Encoding: 8bit")
            lines.append("")
            lines.append(draft.bodyText)
        }

        return Data(lines.joined(separator: "\r\n").utf8)
    }

    private static func rfc2822Date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter.string(from: date)
    }

    private static func expect(_ connection: NWConnection, command: String, accepted: [Int]) async throws -> String {
        try await send(connection, data: Data((command + "\r\n").utf8))
        let response = try await receiveLine(connection)
        guard let code = responseCode(response), accepted.contains(code) else {
            throw NSError(domain: "SMTPSender", code: -1, userInfo: [NSLocalizedDescriptionKey: response])
        }
        return response
    }

    private static func send(_ connection: NWConnection, data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private static func receiveLine(_ connection: NWConnection) async throws -> String {
        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let data, !data.isEmpty {
                    continuation.resume(returning: data)
                    return
                }
                if isComplete {
                    continuation.resume(throwing: NSError(domain: "SMTPSender", code: -1, userInfo: [NSLocalizedDescriptionKey: "SMTP connection closed"]))
                } else {
                    continuation.resume(throwing: NSError(domain: "SMTPSender", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty SMTP response"]))
                }
            }
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static func responseCode(_ response: String) -> Int? {
        Int(response.prefix(3))
    }
}
