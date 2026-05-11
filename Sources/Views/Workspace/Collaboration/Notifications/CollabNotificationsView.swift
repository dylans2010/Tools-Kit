import SwiftUI

struct CollabNotificationsView: View {
    @State private var notifications: [CollabNotification] = []
    @State private var filterType: NotificationType?
    @State private var showUnreadOnly = false

    var filteredNotifications: [CollabNotification] {
        notifications.filter { n in
            let matchesType = filterType == nil || n.type == filterType
            let matchesRead = !showUnreadOnly || !n.isRead
            return matchesType && matchesRead
        }
    }

    var body: some View {
        List {
            Section {
                Toggle("Unread Only", isOn: $showUnreadOnly)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        filterChip(nil, label: "All")
                        ForEach(NotificationType.allCases, id: \.self) { type in
                            filterChip(type, label: type.rawValue.capitalized)
                        }
                    }
                }
            }

            Section("Notifications (\(filteredNotifications.count))") {
                ForEach(filteredNotifications) { notification in
                    HStack(spacing: 12) {
                        ZStack {
                            Image(systemName: notification.type.icon)
                                .font(.title3)
                                .foregroundStyle(notification.type.color)
                                .frame(width: 36, height: 36)
                                .background(notification.type.color.opacity(0.1))
                                .clipShape(Circle())
                            if !notification.isRead {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 14, y: -14)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(notification.title)
                                .font(.subheadline)
                                .fontWeight(notification.isRead ? .regular : .bold)
                            Text(notification.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            Text(notification.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button { markAsRead(notification.id) } label: { Label("Read", systemImage: "envelope.open") }
                        Button(role: .destructive) { delete(notification.id) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Mark All Read") { markAllAsRead() }
            }
        }
        .task { loadNotifications() }
    }

    private func filterChip(_ type: NotificationType?, label: String) -> some View {
        Button {
            filterType = type
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(filterType == type ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(filterType == type ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func markAsRead(_ id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
        }
    }

    private func markAllAsRead() {
        for i in notifications.indices { notifications[i].isRead = true }
    }

    private func delete(_ id: UUID) {
        notifications.removeAll { $0.id == id }
    }

    private func loadNotifications() {
        notifications = [
            CollabNotification(title: "New comment on PR #42", message: "Bob commented: 'Looks good, just one small change.'", type: .comment, timestamp: Date().addingTimeInterval(-1800)),
            CollabNotification(title: "Workspace shared", message: "Alice shared 'Project Alpha' workspace with you.", type: .share, timestamp: Date().addingTimeInterval(-3600)),
            CollabNotification(title: "Build succeeded", message: "CI pipeline completed successfully for branch main.", type: .build, timestamp: Date().addingTimeInterval(-7200)),
            CollabNotification(title: "Review requested", message: "Charlie requested your review on 'Fix dark mode'.", type: .review, timestamp: Date().addingTimeInterval(-14400), isRead: true),
            CollabNotification(title: "Mention in discussion", message: "You were mentioned in 'Best practices for SDK development'.", type: .mention, timestamp: Date().addingTimeInterval(-28800), isRead: true),
        ]
    }
}

private struct CollabNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool = false
}

private enum NotificationType: String, CaseIterable {
    case comment, share, build, review, mention

    var icon: String {
        switch self {
        case .comment: return "bubble.left"
        case .share: return "person.2"
        case .build: return "hammer"
        case .review: return "eye"
        case .mention: return "at"
        }
    }

    var color: Color {
        switch self {
        case .comment: return .blue
        case .share: return .green
        case .build: return .orange
        case .review: return .purple
        case .mention: return .indigo
        }
    }
}
