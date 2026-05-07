import Foundation
import Combine

/// Protocol for the SDK mail service.
public protocol SDKMailServiceProtocol {
    func send(to: String, subject: String, body: String) async throws
    func listMessages() -> [SDKMailMessage]
    func getMessage(id: UUID) -> SDKMailMessage?
    func searchMessages(query: String) -> [SDKMailMessage]
}

/// Full SDK Mail module — handles message composition, threading, local indexing, and search.
/// All business logic lives here; views only consume this service.
@MainActor
public final class SDKMailService: SDKMailServiceProtocol, ObservableObject {
    public static let shared = SDKMailService()

    @Published public private(set) var messages: [SDKMailMessage] = []
    @Published public private(set) var threads: [String: [SDKMailMessage]] = [:]
    @Published public private(set) var unreadCount: Int = 0

    private let dataStore = SDKDataStore.shared
    private var searchIndex: [String: Set<UUID>] = [:]

    private init() {}

    public func initialize() {
        loadFromStore()
        rebuildIndex()
        syncFromWorkspace()
    }

    // MARK: - Send

    public func send(to: String, subject: String, body: String) async throws {
        // Use existing mail infrastructure
        let accountInfo = MailStore.shared.activeAccount.map { account in
            (emailAddress: account.emailAddress, providerType: account.providerType)
        }
        guard let accountInfo else {
            throw SDKError.executionFailed(reason: "No active mail account configured")
        }

        guard let password = MailKeychainManager.shared.getPassword(for: accountInfo.emailAddress) else {
            throw SDKError.executionFailed(reason: "Missing mail credentials for active account")
        }

        let mailMessage = MailMessage(
            id: UUID().uuidString, threadId: UUID().uuidString,
            from: accountInfo.emailAddress, to: [to], cc: [], bcc: [],
            subject: subject, body: body, htmlBody: nil,
            date: Date(), isRead: true, isStarred: false, attachments: []
        )
        try await MailSMTPService().send(message: mailMessage, user: accountInfo.emailAddress, pass: password, provider: accountInfo.providerType)

        let sdkMessage = SDKMailMessage(from: accountInfo.emailAddress, to: [to], subject: subject, body: body, isRead: true)
        try dataStore.save(sdkMessage)
        messages.insert(sdkMessage, at: 0)
        indexMessage(sdkMessage)
        updateThreads()

        SDKEventBus.shared.publish(SDKBusEvent(channel: "mail", name: "mail.sent", data: ["to": to, "subject": subject]))
        await SDKLogStore.shared.log("Mail sent to \(to)", source: "SDKMailService", level: .info)
    }

    // MARK: - Read

    public func listMessages() -> [SDKMailMessage] {
        return messages
    }

    public func getMessage(id: UUID) -> SDKMailMessage? {
        return messages.first { $0.id == id }
    }

    public func getThread(threadId: String) -> [SDKMailMessage] {
        return threads[threadId] ?? []
    }

    // MARK: - Search

    public func searchMessages(query: String) -> [SDKMailMessage] {
        let lowered = query.lowercased()
        let indexResults = searchIndex.filter { $0.key.contains(lowered) }.flatMap { $0.value }
        let indexSet = Set(indexResults)

        if !indexSet.isEmpty {
            return messages.filter { indexSet.contains($0.id) }
        }

        return messages.filter {
            $0.subject.lowercased().contains(lowered) ||
            $0.body.lowercased().contains(lowered) ||
            $0.from.lowercased().contains(lowered) ||
            $0.to.joined(separator: " ").lowercased().contains(lowered)
        }
    }

    // MARK: - Mark Read/Star

    public func markAsRead(id: UUID) throws {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].isRead = true
        messages[index].updatedAt = Date()
        try dataStore.save(messages[index])
        updateUnreadCount()
    }

    public func toggleStar(id: UUID) throws {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].isStarred.toggle()
        messages[index].updatedAt = Date()
        try dataStore.save(messages[index])
    }

    // MARK: - Delete

    public func deleteMessage(id: UUID) throws {
        try dataStore.delete(SDKMailMessage.self, id: id)
        messages.removeAll { $0.id == id }
        updateThreads()
        updateUnreadCount()
        SDKEventBus.shared.publish(SDKBusEvent(channel: "mail", name: "mail.deleted", data: ["id": id.uuidString]))
    }

    // MARK: - Private

    private func loadFromStore() {
        messages = dataStore.fetchAll(SDKMailMessage.self)
        updateThreads()
        updateUnreadCount()
    }

    private func syncFromWorkspace() {
        let workspaceMessages = MailStorageService.shared.threads.flatMap { $0.messages }
        for msg in workspaceMessages {
            let exists = messages.contains { $0.subject == msg.subject && $0.from == msg.from && abs($0.createdAt.timeIntervalSince(msg.date)) < 1 }
            if !exists {
                let sdkMsg = SDKMailMessage(
                    from: msg.from, to: msg.to, cc: msg.cc, bcc: msg.bcc,
                    subject: msg.subject, body: msg.body,
                    htmlBody: msg.htmlBody, isRead: msg.isRead,
                    isStarred: msg.isStarred, threadId: msg.threadId
                )
                try? dataStore.save(sdkMsg)
                messages.append(sdkMsg)
            }
        }
        messages.sort { $0.createdAt > $1.createdAt }
        updateThreads()
        updateUnreadCount()
    }

    private func updateThreads() {
        threads = Dictionary(grouping: messages, by: { $0.threadId })
    }

    private func updateUnreadCount() {
        unreadCount = messages.filter { !$0.isRead }.count
    }

    private func rebuildIndex() {
        searchIndex.removeAll()
        for msg in messages {
            indexMessage(msg)
        }
    }

    private func indexMessage(_ msg: SDKMailMessage) {
        let terms = [msg.subject, msg.body, msg.from].joined(separator: " ").lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count > 2 }
        for term in terms {
            if searchIndex[term] == nil { searchIndex[term] = [] }
            searchIndex[term]?.insert(msg.id)
        }
    }
}
