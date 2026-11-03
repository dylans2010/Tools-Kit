import SwiftUI
import UserNotifications

struct Diag_SecNotificationsAuthDetailView: View {
    @State private var auth = "Unknown"
    @State private var pending = 0
    @State private var delivered = 0

    var body: some View {
        Form {
            Section("Notifications") {
                LabeledContent("Authorization") { Text(auth) }
                LabeledContent("Pending Requests") { Text("\(pending)").monospacedDigit() }
                LabeledContent("Delivered") { Text("\(delivered)").monospacedDigit() }
            }
            Section { Button("Refresh") { load() } }
        }
        .navigationTitle("Notifications Auth")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { auth = String(describing: settings.authorizationStatus) }
        }
        center.getPendingNotificationRequests { reqs in
            DispatchQueue.main.async { pending = reqs.count }
        }
        center.getDeliveredNotifications { notifs in
            DispatchQueue.main.async { delivered = notifs.count }
        }
    }
}
