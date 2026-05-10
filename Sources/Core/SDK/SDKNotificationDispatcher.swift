// ToolsKit — SDKNotificationDispatcher.swift
// SDK Expansion — Phase 3

import Foundation
import Combine

/// Protocol for SDK notification dispatch.
@MainActor
public protocol SDKNotificationDispatcherProtocol: AnyObject {
    func send(_ notification: SDKNotification)
    func markAsRead(id: UUID)
    func dismiss(id: UUID)
    func clearAll()
    var unreadCount: Int { get }
    var notifications: [SDKNotification] { get }
}

/// Represents an SDK notification.
public struct SDKNotification: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var body: String
    public var category: Category
    public var priority: Priority
    public var isRead: Bool
    public var isDismissed: Bool
    public var createdAt: Date
    public var source: String
    public var metadata: [String: String]

    public enum Category: String, Codable, Sendable, CaseIterable {
        case info
        case warning
        case error
        case success
        case system
    }

    public enum Priority: String, Codable, Sendable, CaseIterable {
        case low
        case normal
        case high
        case critical
    }

    public init(
        title: String,
        body: String,
        category: Category = .info,
        priority: Priority = .normal,
        source: String = "SDK",
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.category = category
        self.priority = priority
        self.isRead = false
        self.isDismissed = false
        self.createdAt = Date()
        self.source = source
        self.metadata = metadata
    }
}

/// Centralized notification dispatcher for the SDK.
@MainActor
public final class SDKNotificationDispatcher: SDKNotificationDispatcherProtocol, ObservableObject {
    public static let shared = SDKNotificationDispatcher()

    @Published public private(set) var notifications: [SDKNotification] = []
    @Published public private(set) var unreadCount: Int = 0

    private let maxNotifications: Int = 200
    private let persistenceKey = "sdk_notifications_v1"

    private init() {
        loadNotifications()
    }

    public func send(_ notification: SDKNotification) {
        notifications.insert(notification, at: 0)

        if notifications.count > maxNotifications {
            notifications = Array(notifications.prefix(maxNotifications))
        }

        updateUnreadCount()
        saveNotifications()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.notifications",
            name: "notification.sent",
            data: [
                "id": notification.id.uuidString,
                "title": notification.title,
                "category": notification.category.rawValue,
                "priority": notification.priority.rawValue
            ]
        ))
    }

    public func markAsRead(id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
        updateUnreadCount()
        saveNotifications()
    }

    public func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
        saveNotifications()
    }

    public func dismiss(id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isDismissed = true
        notifications[index].isRead = true
        updateUnreadCount()
        saveNotifications()
    }

    public func clearAll() {
        notifications.removeAll()
        updateUnreadCount()
        saveNotifications()
    }

    public func clearDismissed() {
        notifications.removeAll { $0.isDismissed }
        updateUnreadCount()
        saveNotifications()
    }

    public var visibleNotifications: [SDKNotification] {
        notifications.filter { !$0.isDismissed }
    }

    public func notifications(forCategory category: SDKNotification.Category) -> [SDKNotification] {
        notifications.filter { $0.category == category && !$0.isDismissed }
    }

    public func notifications(forPriority priority: SDKNotification.Priority) -> [SDKNotification] {
        notifications.filter { $0.priority == priority && !$0.isDismissed }
    }

    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead && !$0.isDismissed }.count
    }

    private func saveNotifications() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadNotifications() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let loaded = try? JSONDecoder().decode([SDKNotification].self, from: data)
        else { return }
        notifications = loaded
        updateUnreadCount()
    }
}
