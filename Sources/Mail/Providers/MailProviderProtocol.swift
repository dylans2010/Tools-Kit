import Foundation
import SwiftUI

struct MailCredentials: Sendable {
    var email: String
    var password: String?
    var host: String?
    var port: UInt16?
    var smtpHost: String?
    var smtpPort: UInt16?
    // Raw tokens are only used during the initial authentication phase.
    // They are NOT stored in these persistent models.
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
    var accessTokenExpiration: Date?
    var imapHost: String?
    var imapPort: UInt16?
    var smtpHost: String?
    var smtpPort: UInt16?

    init(
        id: String = UUID().uuidString,
        provider: MailAccount.ProviderType,
        email: String,
        displayName: String,
        accessTokenExpiration: Date? = nil,
        imapHost: String? = nil,
        imapPort: UInt16? = nil,
        smtpHost: String? = nil,
        smtpPort: UInt16? = nil
    ) {
        self.id = id
        self.provider = provider
        self.email = email
        self.displayName = displayName
        self.accessTokenExpiration = accessTokenExpiration
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

    func fetchFolders() async throws -> [MailFolder]
    func fetchThreads(in folder: MailFolder, limit: Int, offset: Int) async throws -> [MailThread]
    func sendMessage(_ message: MailMessage) async throws
    func markAsRead(_ threadId: String) async throws
    func deleteThread(_ threadId: String) async throws
    func starThread(_ threadId: String, starred: Bool) async throws
}

protocol StandardMailProvider {
    func fetchInbox() async throws -> [MailMessage]
    func fetchMessage(id: String) async throws -> MailMessage
    func sendEmail(_ draft: MailDraft) async throws
    func refreshToken() async throws
    func listAccounts() async -> [MailAccount]
}
