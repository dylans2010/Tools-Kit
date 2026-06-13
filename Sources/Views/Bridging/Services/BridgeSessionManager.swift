import Foundation
import Security

public final class BridgeSessionManager: ObservableObject {
    public static let shared = BridgeSessionManager()

    private let service = "com.tools-kit.bridging"
    private let deviceListKey = "bridge_paired_devices"

    @Published public private(set) var pairedDevices: [BridgeDevice] = []

    private init() {
        loadDevices()
    }

    // MARK: - Device Management

    private func loadDevices() {
        if let data = UserDefaults.standard.data(forKey: deviceListKey),
           let devices = try? JSONDecoder().decode([BridgeDevice].self, from: data) {
            self.pairedDevices = devices
        }
    }

    private func saveDevices() {
        if let data = try? JSONEncoder().encode(pairedDevices) {
            UserDefaults.standard.set(data, forKey: deviceListKey)
        }
    }

    public func addDevice(_ device: BridgeDevice, token: String) {
        if let index = pairedDevices.firstIndex(where: { $0.id == device.id }) {
            pairedDevices[index] = device
        } else {
            pairedDevices.append(device)
        }
        saveDevices()
        saveToken(token, for: device.id)
    }

    public func removeDevice(_ deviceID: UUID) {
        pairedDevices.removeAll { $0.id == deviceID }
        saveDevices()
        deleteToken(for: deviceID)
    }

    public func updateLastConnected(for deviceID: UUID) {
        if let index = pairedDevices.firstIndex(where: { $0.id == deviceID }) {
            var device = pairedDevices[index]
            device.lastConnected = Date()
            pairedDevices[index] = device
            saveDevices()
        }
    }

    // MARK: - Keychain Security

    private func saveToken(_ token: String, for deviceID: UUID) {
        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID.uuidString,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    public func getToken(for deviceID: UUID) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func deleteToken(for deviceID: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: deviceID.uuidString
        ]
        SecItemDelete(query as CFDictionary)
    }
}
