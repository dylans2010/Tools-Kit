import SwiftUI

struct GitHubNotificationsView: View {
    @State private var notifications: [GitHubNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && notifications.isEmpty {
                ProgressView("Fetching Notifications...")
            } else if notifications.isEmpty {
                ContentUnavailableView(
                    "No Notifications",
                    systemImage: "bell.slash",
                    description: Text("You're all caught up!")
                )
            } else {
                List(notifications) { notification in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: iconFor(notification.subject.type))
                                .foregroundStyle(.blue)
                            Text(notification.subject.title)
                                .font(.subheadline.bold())
                                .lineLimit(2)
                        }

                        Text(notification.repository.fullName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(notification.reason.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())

                            Spacer()

                            Text(notification.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await fetchNotifications()
                }
            }
        }
        .navigationTitle("Notifications")
        .task {
            await fetchNotifications()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown Error")
        }
    }

    private func fetchNotifications() async {
        isLoading = true
        do {
            let fetched: [GitHubNotification] = try await GitHubAPIClient.shared.request(.notifications)
            await MainActor.run {
                self.notifications = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func iconFor(_ type: String) -> String {
        switch type.lowercased() {
        case "issue": return "exclamationmark.circle"
        case "pullrequest": return "arrow.triangle.pull"
        case "commit": return "circle.dashed"
        case "release": return "tag"
        default: return "bell"
        }
    }
}
