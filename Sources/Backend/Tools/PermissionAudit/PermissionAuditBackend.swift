import Foundation
import AVFoundation
import Photos
import Contacts
import CoreLocation
import UserNotifications
import EventKit

struct PermissionItem: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let icon: String
    let status: Status
    let detail: String

    enum Status: Sendable { case granted, denied, undetermined, restricted }

    var color: String {
        switch status {
        case .granted: return "green"
        case .denied: return "red"
        case .undetermined: return "orange"
        case .restricted: return "gray"
        }
    }
    var statusText: String {
        switch status {
        case .granted: return "Granted"
        case .denied: return "Denied"
        case .undetermined: return "Not Requested"
        case .restricted: return "Restricted"
        }
    }
}

@MainActor
final class PermissionAuditBackend: ObservableObject {
    @Published var permissions: [PermissionItem] = []
    @Published var isLoading = false

    var grantedCount: Int { permissions.filter { $0.status == .granted }.count }
    var deniedCount: Int { permissions.filter { $0.status == .denied }.count }

    func audit() {
        isLoading = true
        Task {
            var items: [PermissionItem] = []
            items.append(checkCamera())
            items.append(checkMicrophone())
            items.append(checkPhotos())
            items.append(await checkNotifications())
            items.append(checkContacts())
            items.append(checkCalendar())
            items.append(checkLocation())
            permissions = items
            isLoading = false
        }
    }

    private func checkCamera() -> PermissionItem {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return PermissionItem(
            name: "Camera", icon: "camera.fill",
            status: mapAV(status), detail: "Used for QR scanning, document scan, and color picker"
        )
    }

    private func checkMicrophone() -> PermissionItem {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return PermissionItem(
            name: "Microphone", icon: "mic.fill",
            status: mapAV(status), detail: "Used for audio conversion features"
        )
    }

    private func checkPhotos() -> PermissionItem {
        let status = PHPhotoLibrary.authorizationStatus()
        return PermissionItem(
            name: "Photos", icon: "photo.fill",
            status: mapPhotos(status), detail: "Used for image processing and metadata tools"
        )
    }

    private func checkNotifications() async -> PermissionItem {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let s: PermissionItem.Status
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: s = .granted
        case .denied: s = .denied
        case .notDetermined: s = .undetermined
        @unknown default: s = .undetermined
        }
        return PermissionItem(name: "Notifications", icon: "bell.fill", status: s, detail: "Used for focus tracker reminders")
    }

    private func checkContacts() -> PermissionItem {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        let s: PermissionItem.Status
        switch status {
        case .authorized: s = .granted
        case .limited: s = .granted
        case .denied: s = .denied
        case .notDetermined: s = .undetermined
        case .restricted: s = .restricted
        @unknown default: s = .undetermined
        }
        return PermissionItem(name: "Contacts", icon: "person.fill", status: s, detail: "Used for smart autofill")
    }

    private func checkCalendar() -> PermissionItem {
        let status = EKEventStore.authorizationStatus(for: .event)
        let s: PermissionItem.Status
        switch status {
        case .authorized: s = .granted
        case .fullAccess, .writeOnly: s = .granted
        case .denied: s = .denied
        case .notDetermined: s = .undetermined
        case .restricted: s = .restricted
        @unknown default: s = .undetermined
        }
        return PermissionItem(name: "Calendar", icon: "calendar", status: s, detail: "Used for reminder generator")
    }

    private func checkLocation() -> PermissionItem {
        let status = CLLocationManager().authorizationStatus
        let s: PermissionItem.Status
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: s = .granted
        case .denied: s = .denied
        case .notDetermined: s = .undetermined
        case .restricted: s = .restricted
        @unknown default: s = .undetermined
        }
        return PermissionItem(name: "Location", icon: "location.fill", status: s, detail: "Used for maps and weather")
    }

    private func mapAV(_ status: AVAuthorizationStatus) -> PermissionItem.Status {
        switch status {
        case .authorized: return .granted
        case .denied: return .denied
        case .notDetermined: return .undetermined
        case .restricted: return .restricted
        @unknown default: return .undetermined
        }
    }

    private func mapPhotos(_ status: PHAuthorizationStatus) -> PermissionItem.Status {
        switch status {
        case .authorized, .limited: return .granted
        case .denied: return .denied
        case .notDetermined: return .undetermined
        case .restricted: return .restricted
        @unknown default: return .undetermined
        }
    }
}
