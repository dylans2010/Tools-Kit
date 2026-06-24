import Foundation

final class OpenClawDeviceRegistry: ObservableObject {
    static let shared = OpenClawDeviceRegistry()
    private let storageKey = "openclaw_device_registry"

    @Published var devices: [OpenClawDevice] = []
    @Published var activeDeviceID: String?

    init() {
        load()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([OpenClawDevice].self, from: data) {
            devices = decoded
        }
        activeDeviceID = UserDefaults.standard.string(forKey: "openclaw_active_device")
    }

    func save() {
        if let data = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        UserDefaults.standard.set(activeDeviceID, forKey: "openclaw_active_device")
    }

    func register(_ device: OpenClawDevice) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
        activeDeviceID = device.id
        save()
    }

    func remove(_ deviceID: String) {
        devices.removeAll { $0.id == deviceID }
        if activeDeviceID == deviceID {
            activeDeviceID = devices.first?.id
        }
        OpenClawSecureStore.shared.deleteToken(for: deviceID)
        save()
    }

    var activeDevice: OpenClawDevice? {
        devices.first { $0.id == activeDeviceID }
    }
}
