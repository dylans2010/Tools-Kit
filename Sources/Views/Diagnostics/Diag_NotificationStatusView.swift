import SwiftUI
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(UIKit)
import UIKit
#endif

struct Diag_NotificationStatusView: View {
    @State private var authStatus: String = "Checking..."
    @State private var alertSetting: String = "Unknown"
    @State private var badgeSetting: String = "Unknown"
    @State private var soundSetting: String = "Unknown"
    @State private var lockScreenSetting: String = "Unknown"
    @State private var notificationCenter: String = "Unknown"
    @State private var pendingCount: Int = 0
    @State private var deliveredCount: Int = 0

    var body: some View {
        Form {
            Section("Authorization") {
                HStack {
                    Image(systemName: authIcon)
                        .font(.title2)
                        .foregroundStyle(authColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authStatus)
                            .font(.headline)
                        Text("Push notification permission status")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Notification Settings") {
                LabeledContent("Alerts") { settingBadge(alertSetting) }
                LabeledContent("Badges") { settingBadge(badgeSetting) }
                LabeledContent("Sounds") { settingBadge(soundSetting) }
                LabeledContent("Lock Screen") { settingBadge(lockScreenSetting) }
                LabeledContent("Notification Center") { settingBadge(notificationCenter) }
            }

            Section("Queue") {
                LabeledContent("Pending Notifications") { Text("\(pendingCount)").monospacedDigit() }
                LabeledContent("Delivered Notifications") { Text("\(deliveredCount)").monospacedDigit() }
            }

            Section("Device Push") {
                LabeledContent("Remote Notifications") {
                    Text(UIApplication.shared.isRegisteredForRemoteNotifications ? "Registered" : "Not Registered")
                        .foregroundStyle(UIApplication.shared.isRegisteredForRemoteNotifications ? .green : .secondary)
                }
                LabeledContent("Background Refresh") {
                    Text(backgroundRefreshStatus)
                        .foregroundStyle(UIApplication.shared.backgroundRefreshStatus == .available ? .green : .orange)
                }
            }

            Section {
                Button {
                    refreshStatus()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Status")
                    }
                }

                Button {
                    requestPermission()
                } label: {
                    HStack {
                        Image(systemName: "bell.badge")
                        Text("Request Permission")
                    }
                }
            }
        }
        .navigationTitle("Notification Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshStatus() }
    }

    private var authIcon: String {
        switch authStatus {
        case "Authorized": return "bell.badge.fill"
        case "Denied": return "bell.slash.fill"
        case "Provisional": return "bell.fill"
        default: return "bell"
        }
    }

    private var authColor: Color {
        switch authStatus {
        case "Authorized": return .green
        case "Denied": return .red
        case "Provisional": return .orange
        default: return .secondary
        }
    }

    private var backgroundRefreshStatus: String {
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available: return "Available"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }

    @ViewBuilder
    private func settingBadge(_ setting: String) -> some View {
        Text(setting)
            .foregroundStyle(setting == "Enabled" ? .green : (setting == "Disabled" ? .red : .secondary))
    }

    private func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized: authStatus = "Authorized"
                case .denied: authStatus = "Denied"
                case .notDetermined: authStatus = "Not Determined"
                case .provisional: authStatus = "Provisional"
                case .ephemeral: authStatus = "Ephemeral"
                @unknown default: authStatus = "Unknown"
                }

                alertSetting = settingString(settings.alertSetting)
                badgeSetting = settingString(settings.badgeSetting)
                soundSetting = settingString(settings.soundSetting)
                lockScreenSetting = settingString(settings.lockScreenSetting)
                notificationCenter = settingString(settings.notificationCenterSetting)
            }
        }

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async { pendingCount = requests.count }
        }

        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async { deliveredCount = notifications.count }
        }
    }

    private func settingString(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .notSupported: return "Not Supported"
        @unknown default: return "Unknown"
        }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async { refreshStatus() }
        }
    }
}
