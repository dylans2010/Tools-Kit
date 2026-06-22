import Foundation
import CryptoKit
import SafariServices

@MainActor
class LMLinkAuthManager: ObservableObject {
    static let shared = LMLinkAuthManager()

    @Published var keyId: String?
    @Published var username: String?
    @Published var devices: [LMDevice] = []
    @Published var isScanning = false
    @Published var lastError: AIError?
    @Published var lastSyncTimestamp: Date?

    var isLinked: Bool {
        return keychain.getIsLinked()
    }

    private let keychain = LMLinkKeychainService.shared

    init() {
        self.keyId = keychain.getKeyId()
        self.username = keychain.getUsername()
    }

    func initiateLink() {
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let publicKeyBase64 = publicKey.rawRepresentation.base64EncodedString()
        let id = UUID().uuidString

        do {
            try keychain.savePrivateKey(privateKey)
            try keychain.saveKeyId(id)

            var components = URLComponents(string: "https://lmstudio.ai/authentication-request")!
            components.queryItems = [
                URLQueryItem(name: "keyId", value: id),
                URLQueryItem(name: "publicKey", value: publicKeyBase64),
                URLQueryItem(name: "feature", value: "lmlink"),
                URLQueryItem(name: "returnTo", value: "toolskit://lm-callback"),
                URLQueryItem(name: "clientKind", value: "ios"),
                URLQueryItem(name: "clientVersion", value: "1.0")
            ]

            if let url = components.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }

            self.keyId = id
            // Linking status will be verified after redirect or upon success
        } catch {
            print("LM Link Error: Failed to generate or save keys - \(error)")
        }
    }

    func handleCallback(url: URL) {
        guard url.scheme == "toolskit" && url.host == "lm-callback" else { return }

        Task { @MainActor in
            SDKLogStore.shared.log("LM Link: Authenticated via callback event", source: "LMLinkAuthManager", level: .info)
            do {
                try keychain.saveIsLinked(true)
                self.objectWillChange.send()
                try? await fetchAccountDevices()
            } catch {
                SDKLogStore.shared.log("LM Link: Failed to persist linked state - \(error)", source: "LMLinkAuthManager", level: .error)
            }
        }
    }

    func fetchAccountDevices() async throws -> [LMDevice] {
        isScanning = true
        defer { isScanning = false }

        SDKLogStore.shared.log("LM Link: Orchestrating device discovery and validation", source: "LMLinkAuthManager", level: .info)

        // 1. Resolve cached device graph (if we had persistent storage beyond DiscoveryService memory)
        // For now, we rely on DiscoveryService's logic

        // 2. Trigger discovery service
        let discovery = LMDeviceDiscoveryService.shared
        await discovery.performFullScan()

        // 3. Update local state with validated devices
        self.devices = discovery.discoveredDevices
        self.lastSyncTimestamp = Date()

        // 4. Update username if available from identity (not available in this protocol yet, so we keep Keychain value)
        self.username = keychain.getUsername()

        return self.devices
    }

    func refreshStatus() async {
        self.keyId = keychain.getKeyId()
        self.username = keychain.getUsername()
        try? await fetchAccountDevices()
    }

    func unlink() {
        SDKLogStore.shared.log("LM Link: Unlinking account and purging local state", source: "LMLinkAuthManager", level: .info)
        keychain.deleteKeys()
        self.keyId = nil
        self.devices = []
        self.objectWillChange.send()
    }
}
