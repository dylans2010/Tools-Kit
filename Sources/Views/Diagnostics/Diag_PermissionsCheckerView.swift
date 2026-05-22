import SwiftUI
import AVFoundation
import CoreLocation
import UserNotifications

struct Diag_PermissionsCheckerView: View {
    @State private var permissions: [PermissionItem] = []
    @State private var isChecking = false

    var body: some View {
        Form {
            Section("App Permissions") {
                if permissions.isEmpty {
                    Button("Check All Permissions") {
                        checkPermissions()
                    }
                } else {
                    ForEach(permissions) { perm in
                        HStack {
                            Image(systemName: perm.icon)
                                .foregroundStyle(perm.statusColor)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(perm.name)
                                    .font(.subheadline.weight(.medium))
                                Text(perm.status)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: perm.statusIcon)
                                .foregroundStyle(perm.statusColor)
                        }
                    }
                }
            }

            if !permissions.isEmpty {
                Section {
                    Button("Refresh") {
                        checkPermissions()
                    }
                }

                Section {
                    Text("To change permissions, go to Settings > Privacy & Security.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Permissions Checker")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkPermissions() }
    }

    private func checkPermissions() {
        isChecking = true
        var items: [PermissionItem] = []

        // Camera
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        items.append(PermissionItem(name: "Camera", icon: "camera.fill", status: authStatusString(cameraStatus), statusColor: authStatusColor(cameraStatus), statusIcon: authStatusIcon(cameraStatus)))

        // Microphone
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        items.append(PermissionItem(name: "Microphone", icon: "mic.fill", status: authStatusString(micStatus), statusColor: authStatusColor(micStatus), statusIcon: authStatusIcon(micStatus)))

        // Location
        let locStatus = CLLocationManager.authorizationStatus()
        items.append(PermissionItem(name: "Location", icon: "location.fill", status: locationStatusString(locStatus), statusColor: locationStatusColor(locStatus), statusIcon: locationStatusIcon(locStatus)))

        // Notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let notifStatus = settings.authorizationStatus
            let item = PermissionItem(name: "Notifications", icon: "bell.fill", status: notifStatusString(notifStatus), statusColor: notifStatusColor(notifStatus), statusIcon: notifStatusIcon(notifStatus))
            DispatchQueue.main.async {
                items.append(item)
                permissions = items
                isChecking = false
            }
        }
    }

    private func authStatusString(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private func authStatusColor(_ status: AVAuthorizationStatus) -> Color {
        switch status {
        case .authorized: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .orange
        @unknown default: return .secondary
        }
    }

    private func authStatusIcon(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "checkmark.circle.fill"
        case .denied, .restricted: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        @unknown default: return "questionmark.circle"
        }
    }

    private func locationStatusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private func locationStatusColor(_ status: CLAuthorizationStatus) -> Color {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .orange
        @unknown default: return .secondary
        }
    }

    private func locationStatusIcon(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return "checkmark.circle.fill"
        case .denied, .restricted: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        @unknown default: return "questionmark.circle"
        }
    }

    private func notifStatusString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private func notifStatusColor(_ status: UNAuthorizationStatus) -> Color {
        switch status {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .secondary
        }
    }

    private func notifStatusIcon(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized, .provisional, .ephemeral: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        @unknown default: return "questionmark.circle"
        }
    }
}

private struct PermissionItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let status: String
    let statusColor: Color
    let statusIcon: String
}
