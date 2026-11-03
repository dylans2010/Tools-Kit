import SwiftUI
import AVFoundation
import Photos
import CoreLocation
import UserNotifications
import AppTrackingTransparency
import Contacts
import CoreMotion

/// Real permission report for THIS app. The previous version listed
/// fake accesses by other apps ("Photos 42 times", "Maps 12 times") —
/// iOS does not let an app see other apps' privacy logs, so those
/// entries were invented. This version reports only this app's own
/// authorization statuses, read from the real frameworks, with no prompts.
struct Diag_PrivacyReportView: View {
    @State private var rows: [(String, String)] = []
    @State private var notificationStatus = "—"

    var body: some View {
        List {
            Section("This App's Permissions") {
                ForEach(rows, id: \.0) { row in
                    LabeledContent(row.0) { Text(row.1).font(.caption) }
                }
            }

            Section("System Audit") {
                LabeledContent("App Tracking Transparency") { Text(ATTrackingManager.trackingAuthorizationStatus == .authorized ? "Authorized" : "Not authorized") }
                LabeledContent("Notification Authorization") { Text(notificationStatus).font(.caption) }
            }

            Section {
                Text("iOS does not expose other apps' privacy-access history to an app, so a system-wide 'recent access' log cannot be shown here. The rows above are this app's real authorization statuses, read on appear and on Refresh — not a stored log.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Refresh") { load() }
            }
        }
        .navigationTitle("App Privacy Report")
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Camera", statusText(AVCaptureDevice.authorizationStatus(for: .video))),
            ("Microphone", statusText(AVCaptureDevice.authorizationStatus(for: .audio))),
            ("Photo Library", photoStatus()),
            ("Location", locationStatus()),
            ("Contacts", contactsStatus()),
            ("Motion & Fitness", motionStatus()),
        ]
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let text: String
            switch settings.authorizationStatus {
            case .authorized: text = "Authorized"
            case .denied: text = "Denied"
            case .notDetermined: text = "Not determined"
            case .provisional: text = "Provisional"
            case .ephemeral: text = "Ephemeral"
            @unknown default: text = "Unknown"
            }
            DispatchQueue.main.async { notificationStatus = text }
        }
    }

    private func statusText(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not determined"
        @unknown default: return "Unknown"
        }
    }

    private func photoStatus() -> String {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized: return "Authorized"
        case .limited: return "Limited"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not determined"
        @unknown default: return "Unknown"
        }
    }

    private func locationStatus() -> String {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When in use"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not determined"
        @unknown default: return "Unknown"
        }
    }

    private func contactsStatus() -> String {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not determined"
        @unknown default: return "Unknown"
        }
    }

    private func motionStatus() -> String {
        switch CMAltimeter.authorizationStatus() {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not determined"
        @unknown default: return "Unknown"
        }
    }
}

struct PrivacyEntry: Identifiable {
    let id = UUID()
    let app: String
    let category: String
    let lastAccess: Date
    let count: Int
}
