import Foundation
import SwiftUI
import CryptoKit

enum AppConfig {
    private static func mustString(_ key: String) -> String {
        do {
            return try requiredString(key)
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }

    static func requiredString(_ key: String) throws -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            throw NSError(domain: "AppConfig", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing \(key) in Info.plist"])
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "AppConfig", code: 500, userInfo: [NSLocalizedDescriptionKey: "Empty \(key) in Info.plist"])
        }
        return trimmed
    }

    static var googleClientID: String { mustString("GOOGLE_OAUTH_CLIENT_ID") }
    static var microsoftClientID: String { mustString("MICROSOFT_OAUTH_CLIENT_ID") }
    static var yahooClientID: String { mustString("YAHOO_OAUTH_CLIENT_ID") }

    static var googleRedirectURI: String { mustString("GOOGLE_OAUTH_REDIRECT_URI") }
    static var microsoftRedirectURI: String { mustString("MICROSOFT_OAUTH_REDIRECT_URI") }
    static var yahooRedirectURI: String { mustString("YAHOO_OAUTH_REDIRECT_URI") }
}

struct MailCredentials: Sendable {
    var email: String
    var password: String?
    var host: String?
    var port: UInt16?
    var smtpHost: String?
    var smtpPort: UInt16?
    var accessToken: String?
    var refreshToken: String?

    static func oauth(email: String = "") -> MailCredentials {
        MailCredentials(
            email: email,
            password: nil,
            host: nil,
            port: nil,
            smtpHost: nil,
            smtpPort: nil,
            accessToken: nil,
            refreshToken: nil
        )
    }
}

struct MailSession: Identifiable, Codable, Sendable {
    var id: String
    var provider: MailAccount.ProviderType
    var email: String
    var displayName: String
    var accessToken: String?
    var refreshToken: String?
    var imapHost: String?
    var imapPort: UInt16?
    var smtpHost: String?
    var smtpPort: UInt16?

    init(
        id: String = UUID().uuidString,
        provider: MailAccount.ProviderType,
        email: String,
        displayName: String,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        imapHost: String? = nil,
        imapPort: UInt16? = nil,
        smtpHost: String? = nil,
        smtpPort: UInt16? = nil
    ) {
        self.id = id
        self.provider = provider
        self.email = email
        self.displayName = displayName
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.imapHost = imapHost
        self.imapPort = imapPort
        self.smtpHost = smtpHost
        self.smtpPort = smtpPort
    }
}

struct MailDraft: Sendable {
    var from: String
    var to: [String]
    var cc: [String]
    var bcc: [String]
    var subject: String
    var bodyText: String
    var bodyHTML: String?

    init(from: String, to: [String], cc: [String] = [], bcc: [String] = [], subject: String, bodyText: String, bodyHTML: String? = nil) {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.bodyText = bodyText
        self.bodyHTML = bodyHTML
    }
}

protocol MailProvider {
    var displayName: String { get }
    var iconAssetName: String { get }
    var primaryColor: Color { get }

    func authenticate(credentials: MailCredentials) async throws -> MailSession
    func fetchInbox(session: MailSession, page: Int) async throws -> [MailMessage]
    func fetchMessage(session: MailSession, id: String) async throws -> MailMessage
    func sendMessage(session: MailSession, draft: MailDraft) async throws
    func saveDraft(session: MailSession, draft: MailDraft) async throws
    func deleteMessage(session: MailSession, id: String) async throws
    func markRead(session: MailSession, id: String) async throws
}

protocol MailProviderProtocol {
    var account: MailAccount { get }

    func fetchInbox() async throws -> [EmailMessage]
    func fetchMessage(id: String) async throws -> EmailMessage
    func sendEmail() async throws
    func refreshToken() async throws
    func listAccounts() -> [EmailAccount]

    func fetchFolders() async throws -> [MailFolder]
    func fetchThreads(in folder: MailFolder, limit: Int, offset: Int) async throws -> [MailThread]
    func sendMessage(_ message: MailMessage) async throws
    func markAsRead(_ threadId: String) async throws
    func deleteThread(_ threadId: String) async throws
    func starThread(_ threadId: String, starred: Bool) async throws
}

extension MailProviderProtocol {
    func fetchInbox() async throws -> [EmailMessage] {
        let threads = try await fetchThreads(in: .inbox, limit: 30, offset: 0)
        return threads.compactMap { thread in
            guard let last = thread.messages.last else { return nil }
            return EmailMessage(
                uid: stableUID(from: last.id),
                subject: last.subject,
                sender: last.from,
                date: last.date,
                preview: last.body,
                isRead: last.isRead,
                body: last.body,
                htmlBody: last.htmlBody,
                attachments: []
            )
        }
    }

    func fetchMessage(id: String) async throws -> EmailMessage {
        let threads = try await fetchThreads(in: .inbox, limit: 50, offset: 0)
        if let message = threads.flatMap(\.messages).first(where: { $0.id == id }) {
            return EmailMessage(
                uid: stableUID(from: message.id),
                subject: message.subject,
                sender: message.from,
                date: message.date,
                preview: message.body,
                isRead: message.isRead,
                body: message.body,
                htmlBody: message.htmlBody,
                attachments: []
            )
        }
        throw NSError(domain: "MailProviderProtocol", code: 404, userInfo: [NSLocalizedDescriptionKey: "Message not found"])
    }

    func sendEmail() async throws {
        throw NSError(domain: "MailProviderProtocol", code: 501, userInfo: [NSLocalizedDescriptionKey: "sendEmail requires provider-specific payload"])
    }

    func refreshToken() async throws {}

    func listAccounts() -> [EmailAccount] {
        []
    }

    private func stableUID(from id: String) -> Int {
        if let parsed = Int(id), parsed > 0 { return parsed }
        let digest = SHA256.hash(data: Data(id.utf8))
        let prefix = digest.prefix(8)
        let hashed = prefix.reduce(into: UInt64(0)) { result, byte in
            result = (result << 8) | UInt64(byte)
        }
        let safe = hashed % UInt64(Int.max - 1)
        return Int(max(safe, 1))
    }
}
