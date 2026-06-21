import Foundation
import CryptoKit
import SafariServices

@MainActor
class LMLinkAuthManager: ObservableObject {
    static let shared = LMLinkAuthManager()

    @Published var isLinked = false
    @Published var keyId: String?

    private let keychain = LMLinkKeychainService.shared

    init() {
        self.keyId = keychain.getKeyId()
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
                URLQueryItem(name: "returnTo", value: "toolskit"),
                URLQueryItem(name: "clientKind", value: "ios"),
                URLQueryItem(name: "clientVersion", value: "1.0")
            ]

            if let url = components.url {
                UIApplication.shared.open(url)
            }

            self.keyId = id
            // Linking status will be verified after redirect or upon success
        } catch {
            print("LM Link Error: Failed to generate or save keys - \(error)")
        }
    }

    func confirmLink() {
        self.isLinked = true
    }

    func unlink() {
        keychain.deleteKeys()
        self.keyId = nil
        self.isLinked = false
    }
}
