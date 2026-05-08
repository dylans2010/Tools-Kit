import Foundation

/// Protocol for the SDK mail service.
@MainActor
public protocol SDKMailServiceProtocol {
    func send(to: String, subject: String, body: String) async throws
    func listMessages() -> [SDKMailMessage]
    func getMessage(id: UUID) -> SDKMailMessage?
    func searchMessages(query: String) -> [SDKMailMessage]
    func getThreads() -> [String: [SDKMailMessage]]
    func deleteMessage(id: UUID) throws
}

/// Full SDK Mail module — handles message composition, threading, local indexing, and search.
@MainActor
public final class SDKMailService: SDKMailServiceProtocol, ObservableObject {
    public static let shared = SDKMailService()

    @Published public private(set) var messages: [SDKMailMessage] = []
    @Published public private(set) var threads: [String: [SDKMailMessage]] = [:]
    @Published public private(set) var unreadCount: Int = 0

    private let dataStore = SDKDataStore.shared
    private let queryEngine = SDKQueryEngine.self
    private var searchIndex: [String: Set<UUID>] = [:]

    private init() {}

    public func initialize() {
        loadFromStore()
        rebuildIndex()
        syncFromWorkspace()
    }

    public func send(to: String, subject: String, body: String) async throws {
        guard SDKPermissionManager.shared.isScopeAuthorized("mail.send") else {
            throw SDKError.permissionDenied(scope: "mail.send")
        }

        let account = MailStore.shared.activeAccount
        guard let accountInfo = account else {
            throw SDKError.executionFailed(reason: "No active mail account")
        }

        let sdkMessage = SDKMailMessage(from: accountInfo.emailAddress, to: [to], subject: subject, body: body, isRead: true)
        try dataStore.save(sdkMessage)
        messages.insert(sdkMessage, at: 0)
        indexMessage(sdkMessage)
        updateThreads()

        SDKEventBus.shared.publish(SDKBusEvent(channel: "mail", name: "mail.sent", data: ["to": to, "subject": subject]))
    }

    public func listMessages() -> [SDKMailMessage] {
        return messages
    }

    public func getMessage(id: UUID) -> SDKMailMessage? {
        return messages.first { $0.id == id }
    }

    public func getThreads() -> [String: [SDKMailMessage]] {
        return threads
    }

    public func searchMessages(query: String) -> [SDKMailMessage] {
        if query.isEmpty { return messages }
        return queryEngine.search(messages, query: query, fields: [\.subject, \.body, \.from])
    }

    public func deleteMessage(id: UUID) throws {
        try dataStore.delete(SDKMailMessage.self, id: id)
        messages.removeAll { $0.id == id }
        updateThreads()
        updateUnreadCount()
    }

    private func loadFromStore() {
        messages = dataStore.fetchAll(SDKMailMessage.self)
        updateThreads()
        updateUnreadCount()
    }

    private func syncFromWorkspace() {
        // Implementation for sync
    }

    private func updateThreads() {
        threads = Dictionary(grouping: messages, by: { $0.threadId })
    }

    private func updateUnreadCount() {
        unreadCount = messages.filter { !$0.isRead }.count
    }

    private func rebuildIndex() {
        searchIndex.removeAll()
        for msg in messages { indexMessage(msg) }
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
