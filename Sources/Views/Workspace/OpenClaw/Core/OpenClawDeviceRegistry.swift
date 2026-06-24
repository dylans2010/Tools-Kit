import Foundation

struct OpenClawDevice: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let host: String
    let port: Int
    var lastConnected: Date?

    var url: URL? {
        URL(string: "ws://\(host):\(port)")
    }
}

@Observable
final class OpenClawDeviceRegistry {
    static let shared = OpenClawDeviceRegistry()
    private let storageKey = "openclaw_paired_devices"

    var devices: [OpenClawDevice] = []

    private init() {
        load()
    }

    func register(_ device: OpenClawDevice) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
        save()
    }

    func unregister(_ deviceId: String) {
        devices.removeAll(where: { $0.id == deviceId })
        OpenClawSecureStore.shared.deleteToken(for: deviceId)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([OpenClawDevice].self, from: data) {
            devices = saved
        }
    }
}
