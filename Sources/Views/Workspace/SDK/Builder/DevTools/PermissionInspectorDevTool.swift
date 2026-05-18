import SwiftUI
import AVFoundation
import CoreLocation
import UserNotifications

struct PermissionInspectorTool: DevTool {
    let id = UUID()
    let name = "Permission Inspector"
    let category: DevToolCategory = .security
    let icon = "lock.shield"
    let description = "Check app permission status"
    func render() -> some View { PermissionInspectorDevToolView() }
}

struct PermissionInspectorDevToolView: View {
    @State private var permissions: [(String, String, String)] = []

    var body: some View {
        Form {
            Section {
                Button("Check Permissions") { checkPermissions() }
            }
            Section("Permissions") {
                ForEach(Array(permissions.enumerated()), id: \.offset) { _, perm in
                    HStack {
                        Image(systemName: perm.2)
                            .foregroundStyle(statusColor(perm.1))
                        VStack(alignment: .leading) {
                            Text(perm.0).font(.subheadline)
                            Text(perm.1).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Circle().fill(statusColor(perm.1)).frame(width: 8, height: 8)
                    }
                }
            }
        }
        .navigationTitle("Permission Inspector")
        .onAppear { checkPermissions() }
    }

    private func checkPermissions() {
        permissions.removeAll()
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        permissions.append(("Camera", authStatusString(cameraStatus), "camera"))
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        permissions.append(("Microphone", authStatusString(micStatus), "mic"))
        let locStatus = CLLocationManager().authorizationStatus
        permissions.append(("Location", locationStatusString(locStatus), "location"))
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                permissions.append(("Notifications", notifStatusString(settings.authorizationStatus), "bell"))
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

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Authorized", "Always", "When In Use": return .green
        case "Denied", "Restricted": return .red
        default: return .orange
        }
    }
}
