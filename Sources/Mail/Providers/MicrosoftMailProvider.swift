import Foundation

final class MicrosoftMailProvider: StandardMailProvider {
    private let provider = OutlookProvider()
    private let session: MailSession

    init(session: MailSession) {
        self.session = session
    }

    func fetchInbox() async throws -> [MailMessage] {
        try await provider.fetchInbox(session: session, page: 0)
    }

    func fetchMessage(id: String) async throws -> MailMessage {
        try await provider.fetchMessage(session: session, id: id)
    }

    func sendEmail(_ draft: MailDraft) async throws {
        try await provider.sendMessage(session: session, draft: draft)
    }

    func refreshToken() async throws {
        _ = try await provider.refreshSessionToken(session: session)
    }

    func listAccounts() async -> [MailAccount] {
        await MainActor.run {
            MailStore.shared.accounts.filter { $0.provider == .outlook }
        }
    }
}
