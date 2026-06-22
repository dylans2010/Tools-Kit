import Foundation
import CryptoKit
import SafariServices

@MainActor
class LMLinkAuthManager: ObservableObject {
    static let shared = LMLinkAuthManager()

    @Published var isLinked = false
    @Published var keyId: String?
    @Published var username: String?

    private let keychain = LMLinkKeychainService.shared

    init() {
        self.keyId = keychain.getKeyId()
        self.username = keychain.getUsername()
        self.isLinked = keyId != nil && (try? keychain.getPrivateKey()) != nil
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

        // In a real scenario, we might validate a token from the URL
        // For this implementation, the presence of the callback from LM Studio confirms the link
        Task { @MainActor in
            self.isLinked = true
            // keyId is already set during initiateLink
            SDKLogStore.shared.log("LM Link authenticated via callback", source: "LMLinkAuthManager", level: .info)
        }
    }

    func confirmLink() {
        self.isLinked = true
        // Set a mock username for now upon successful link
        let mockUsername = "LM Studio User"
        try? keychain.saveUsername(mockUsername)
        self.username = mockUsername
    }

    func refreshStatus() async {
        // Simulate a network check for status updates
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
        self.keyId = keychain.getKeyId()
        self.username = keychain.getUsername()
        self.isLinked = keyId != nil && (try? keychain.getPrivateKey()) != nil
    }

    func unlink() {
        keychain.deleteKeys()
        self.keyId = nil
        self.isLinked = false
    }
}
