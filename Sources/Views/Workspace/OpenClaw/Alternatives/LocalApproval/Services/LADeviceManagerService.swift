import Foundation
import Observation

@Observable
public final class LADeviceManagerService {
    public static let shared = LADeviceManagerService()
    private let userDefaults = UserDefaults.standard
    private let storageKey = "com.toolskit.openclaw.local-approval.devices"
    private let blocklistKey = "com.toolskit.openclaw.local-approval.blocklist"

    public private(set) var trustedDevices: [LADevice] = []
    public private(set) var blockedAppInstallIds: Set<String> = []

    private init() {
        loadDevices()
        loadBlocklist()
    }

    public func addDevice(_ device: LADevice) {
        if let index = trustedDevices.firstIndex(where: { $0.id == device.id }) {
            trustedDevices[index] = device
        } else {
            trustedDevices.append(device)
        }
        saveDevices()
    }

    public func removeDevice(id: String) {
        trustedDevices.removeAll(where: { $0.id == id })
        saveDevices()
    }

    public func blockDevice(appInstallId: String) {
        blockedAppInstallIds.insert(appInstallId)
        saveBlocklist()
    }

    public func unblockDevice(appInstallId: String) {
        blockedAppInstallIds.remove(appInstallId)
        saveBlocklist()
    }

    private func loadDevices() {
        if let data = userDefaults.data(forKey: storageKey),
           let devices = try? JSONDecoder().decode([LADevice].self, from: data) {
            self.trustedDevices = devices
        }
    }

    private func saveDevices() {
        if let data = try? JSONEncoder().encode(trustedDevices) {
            userDefaults.set(data, forKey: storageKey)
        }
    }

    private func loadBlocklist() {
        if let array = userDefaults.stringArray(forKey: blocklistKey) {
            self.blockedAppInstallIds = Set(array)
        }
    }

    private func saveBlocklist() {
        userDefaults.set(Array(blockedAppInstallIds), forKey: blocklistKey)
    }
}
