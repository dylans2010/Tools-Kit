import SwiftUI
import UserNotifications

struct Diag_NotificationStatusView: View {
    @State private var authStatus: String = "Checking..."
    @State private var alertSetting: String = "—"
    @State private var soundSetting: String = "—"
    @State private var badgeSetting: String = "—"
    @State private var lockScreenSetting: String = "—"
    @State private var notificationCenterSetting: String = "—"
    @State private var showPreviewsSetting: String = "—"

    var body: some View {
        Form {
            Section("Authorization") {
                LabeledContent("Status") {
                    Text(authStatus)
                        .foregroundStyle(authColor)
                }
            }

            Section("Settings") {
                LabeledContent("Alerts") { Text(alertSetting) }
                LabeledContent("Sounds") { Text(soundSetting) }
                LabeledContent("Badges") { Text(badgeSetting) }
                LabeledContent("Lock Screen") { Text(lockScreenSetting) }
                LabeledContent("Notification Center") { Text(notificationCenterSetting) }
                LabeledContent("Show Previews") { Text(showPreviewsSetting) }
            }

            Section {
                Button("Refresh") {
                    checkStatus()
                }
            }
        }
        .navigationTitle("Notification Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkStatus() }
    }

    private var authColor: Color {
        switch authStatus {
        case "Authorized": return .green
        case "Denied": return .red
        default: return .orange
        }
    }

    private func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized: authStatus = "Authorized"
                case .denied: authStatus = "Denied"
                case .provisional: authStatus = "Provisional"
                case .ephemeral: authStatus = "Ephemeral"
                case .notDetermined: authStatus = "Not Determined"
                @unknown default: authStatus = "Unknown"
                }

                alertSetting = settingString(settings.alertSetting)
                soundSetting = settingString(settings.soundSetting)
                badgeSetting = settingString(settings.badgeSetting)
                lockScreenSetting = settingString(settings.lockScreenSetting)
                notificationCenterSetting = settingString(settings.notificationCenterSetting)
                showPreviewsSetting = previewString(settings.showPreviewsSetting)
            }
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

    private func previewString(_ setting: UNShowPreviewsSetting) -> String {
        switch setting {
        case .always: return "Always"
        case .whenAuthenticated: return "When Unlocked"
        case .never: return "Never"
        @unknown default: return "Unknown"
        }
    }
}
