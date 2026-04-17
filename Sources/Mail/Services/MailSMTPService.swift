import Foundation
import Network

class MailSMTPService {
    private var host: String = "smtp.mail.me.com"
    private var port: UInt16 = 587
    private var connection: NWConnection?

    func send(message: MailMessage, user: String, pass: String) async throws {
        try await send(message: message, user: user, pass: pass, provider: .iCloud)
    }

    func send(message: MailMessage, user: String, pass: String, provider: MailAccount.MailProviderType) async throws {
        switch provider {
        case .iCloud:
            host = "smtp.mail.me.com"
            port = 587
        case .gmail:
            host = GmailServerConfiguration.smtpHost
            port = GmailServerConfiguration.smtpPort
        }

        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port))
        // SMTP 587 usually starts with plain then STARTTLS
        connection = NWConnection(to: endpoint, using: .tcp)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection?.stateUpdateHandler = { state in
                if case .ready = state { continuation.resume() }
                if case .failed(let err) = state { continuation.resume(throwing: err) }
            }
            connection?.start(queue: .global())
        }

        // Protocol flow:
        // EHLO -> STARTTLS -> EHLO -> AUTH LOGIN -> MAIL FROM -> RCPT TO -> DATA -> . -> QUIT
        _ = try await sendCommand("EHLO tools-kit.app")
        _ = try await sendCommand("STARTTLS")
        // Note: Actual implementation would need to upgrade connection to TLS here.
        // For production, libraries like MailCore2 or custom TLS upgrade logic is needed.

        _ = try await sendCommand("AUTH LOGIN")
        _ = try await sendCommand(Data(user.utf8).base64EncodedString())
        _ = try await sendCommand(Data(pass.utf8).base64EncodedString())

        _ = try await sendCommand("MAIL FROM:<\(user)>")
        for recipient in message.to {
            _ = try await sendCommand("RCPT TO:<\(recipient)>")
        }

        _ = try await sendCommand("DATA")
        let emailContent = "Subject: \(message.subject)\r\n\r\n\(message.body)\r\n.\r\n"
        _ = try await sendCommand(emailContent)
        _ = try await sendCommand("QUIT")

        connection?.cancel()
    }

    private func sendCommand(_ command: String) async throws -> String {
        let fullCommand = command.hasSuffix("\r\n") ? command : "\(command)\r\n"
        return try await withCheckedThrowingContinuation { continuation in
            connection?.send(content: fullCommand.data(using: .utf8), completion: .contentProcessed({ error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                self.connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
                    let response = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    continuation.resume(returning: response)
                }
            }))
        }
    }
}
