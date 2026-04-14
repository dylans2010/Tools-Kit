import Foundation

protocol MailProviderProtocol {
    var account: MailAccount { get }

    func fetchFolders() async throws -> [MailFolder]
    func fetchThreads(in folder: MailFolder, limit: Int, offset: Int) async throws -> [MailThread]
    func sendMessage(_ message: MailMessage) async throws
    func markAsRead(_ threadId: String) async throws
    func deleteThread(_ threadId: String) async throws
    func starThread(_ threadId: String, starred: Bool) async throws
}
