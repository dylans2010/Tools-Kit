import Foundation
import Observation
@Observable public final class TLANDeviceManagerService {
    public static let shared = TLANDeviceManagerService()
    private let userDefaults = UserDefaults.standard; private let storageKey = "com.toolskit.openclaw.trusted-lan.devices"
    public private(set) var trustedDevices: [TLANDevice] = []
    private init() { loadDevices() }
    public func addDevice(_ device: TLANDevice) {
        if let index = trustedDevices.firstIndex(where: { $0.id == device.id }) { trustedDevices[index] = device }
        else { trustedDevices.append(device) }; saveDevices()
    }
    public func removeDevice(id: String) { trustedDevices.removeAll(where: { $0.id == id }); saveDevices() }
    private func loadDevices() {
        if let data = userDefaults.data(forKey: storageKey), let devices = try? JSONDecoder().decode([TLANDevice].self, from: data) { self.trustedDevices = devices }
    }
    private func saveDevices() { if let data = try? JSONEncoder().encode(trustedDevices) { userDefaults.set(data, forKey: storageKey) } }
}
