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
                                .foregroundStyle(color(for: perm.status))
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(perm.name)
                                    .font(.subheadline.weight(.medium))
                                Text(perm.statusText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: icon(for: perm.status))
                                .foregroundStyle(color(for: perm.status))
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
        items.append(PermissionItem(name: "Camera", icon: "camera.fill", status: mapAVStatus(cameraStatus), detail: "Used for QR scanning and media capture"))

        // Microphone
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        items.append(PermissionItem(name: "Microphone", icon: "mic.fill", status: mapAVStatus(micStatus), detail: "Used for audio recording features"))

        // Location
        let locStatus = CLLocationManager.authorizationStatus()
        items.append(PermissionItem(name: "Location", icon: "location.fill", status: mapLocationStatus(locStatus), detail: "Used for location-aware diagnostics"))

        // Notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let notifStatus = settings.authorizationStatus
            let item = PermissionItem(name: "Notifications", icon: "bell.fill", status: mapNotificationStatus(notifStatus), detail: "Used for reminders and alerts")
            DispatchQueue.main.async {
                items.append(item)
                permissions = items
                isChecking = false
            }
        }
    }

    private func mapAVStatus(_ status: AVAuthorizationStatus) -> PermissionItem.Status {
        switch status {
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .undetermined
        @unknown default: return .undetermined
        }
    }

    private func mapLocationStatus(_ status: CLAuthorizationStatus) -> PermissionItem.Status {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .undetermined
        @unknown default: return .undetermined
        }
    }

    private func mapNotificationStatus(_ status: UNAuthorizationStatus) -> PermissionItem.Status {
        switch status {
        case .authorized, .provisional, .ephemeral: return .granted
        case .denied: return .denied
        case .notDetermined: return .undetermined
        @unknown default: return .undetermined
        }
    }

    private func color(for status: PermissionItem.Status) -> Color {
        switch status {
        case .granted: return .green
        case .denied: return .red
        case .undetermined: return .orange
        case .restricted: return .gray
        }
    }

    private func icon(for status: PermissionItem.Status) -> String {
        switch status {
        case .granted: return "checkmark.circle.fill"
        case .denied, .restricted: return "xmark.circle.fill"
        case .undetermined: return "questionmark.circle.fill"
        }
    }
