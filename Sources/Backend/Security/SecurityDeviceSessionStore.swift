import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct SecuritySession: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceName: String
    var location: String
    var lastActive: Date
    var isCurrent: Bool
}

struct TrustedDevice: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var fingerprint: String
    var isCurrent: Bool
    var trustedAt: Date
}

@MainActor
final class SecurityDeviceSessionStore: ObservableObject {
    static let shared = SecurityDeviceSessionStore()

    @Published private(set) var sessions: [SecuritySession] = []
    @Published private(set) var trustedDevices: [TrustedDevice] = []

    private let sessionsFile = "security_sessions.json"
    private let trustedDevicesFile = "security_trusted_devices.json"

    private init() {
        load()
        bootstrapCurrentDeviceIfNeeded()
        refreshCurrentSessionActivity()
    }

    func revokeSession(_ session: SecuritySession) {
        sessions.removeAll { $0.id == session.id || ($0.isCurrent && session.isCurrent) }
        ensureCurrentSessionExists()
        save()
    }

    func revokeAllOtherSessions() {
        sessions.removeAll { !$0.isCurrent }
        ensureCurrentSessionExists()
        save()
    }

    func removeTrustedDevice(_ device: TrustedDevice) {
        guard !device.isCurrent else { return }
        trustedDevices.removeAll { $0.id == device.id }
        save()
    }

    func trustCurrentDevice() {
        if let idx = trustedDevices.firstIndex(where: { $0.isCurrent }) {
            trustedDevices[idx].trustedAt = Date()
        } else {
            trustedDevices.append(currentTrustedDevice())
        }
        save()
    }

    func refreshCurrentSessionActivity() {
        ensureCurrentSessionExists()
        if let index = sessions.firstIndex(where: { $0.isCurrent }) {
            sessions[index].lastActive = Date()
        }
        save()
    }

    private func bootstrapCurrentDeviceIfNeeded() {
        ensureCurrentSessionExists()
        if !trustedDevices.contains(where: { $0.isCurrent }) {
            trustedDevices.append(currentTrustedDevice())
        }
        save()
    }

    private func ensureCurrentSessionExists() {
        if let index = sessions.firstIndex(where: { $0.isCurrent }) {
            sessions[index].deviceName = currentDeviceName()
            return
        }

        sessions.append(SecuritySession(
            id: UUID(),
            deviceName: currentDeviceName(),
            location: "Current Device",
            lastActive: Date(),
            isCurrent: true
        ))
    }

    private func currentTrustedDevice() -> TrustedDevice {
        TrustedDevice(
            id: UUID(),
            name: currentDeviceName(),
            fingerprint: currentFingerprint(),
            isCurrent: true,
            trustedAt: Date()
        )
    }

    private func currentDeviceName() -> String {
        #if canImport(UIKit)
        return UIDevice.current.name
        #else
        return Host.current().localizedName ?? "Current Device"
        #endif
    }

    private func currentFingerprint() -> String {
        if let existing = trustedDevices.first(where: { $0.isCurrent })?.fingerprint {
            return existing
        }
        return "device-\(UUID().uuidString.prefix(12))"
    }

    private func load() {
        sessions = (try? WorkspacePersistence.shared.load([SecuritySession].self, from: sessionsFile)) ?? []
        trustedDevices = (try? WorkspacePersistence.shared.load([TrustedDevice].self, from: trustedDevicesFile)) ?? []
    }

    private func save() {
        try? WorkspacePersistence.shared.save(sessions, to: sessionsFile)
        try? WorkspacePersistence.shared.save(trustedDevices, to: trustedDevicesFile)
    }
}
