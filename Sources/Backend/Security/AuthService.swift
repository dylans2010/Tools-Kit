import Foundation
import LocalAuthentication
import CryptoKit
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var isSetup = false
    @Published var lastActivity: Date = Date()

    private let masterPasswordKey = "com.toolskit.security.master"
    private let saltKey = "com.toolskit.security.salt"
    private let useBiometricsKey = "com.toolskit.security.useBiometrics"
    private let autoLockInterval: TimeInterval = 300 // 5 minutes

    var sessionKey: SymmetricKey?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkSetup()
        setupAutoLockTimer()
    }

    func checkSetup() {
        isSetup = UserDefaults.standard.data(forKey: saltKey) != nil
    }

    func setup(password: String, useBiometrics: Bool) throws {
        let salt = EncryptionService.shared.generateSalt()
        let key = try EncryptionService.shared.deriveKey(password: password, salt: salt)

        UserDefaults.standard.set(salt, forKey: saltKey)
        UserDefaults.standard.set(useBiometrics, forKey: useBiometricsKey)

        let verification = "verified".data(using: .utf8)!
        let encrypted = try EncryptionService.shared.encrypt(verification, using: key)

        saveToKeychain(data: encrypted, service: masterPasswordKey)

        if useBiometrics {
            savePasswordToKeychain(password)
        }

        self.sessionKey = key
        self.isAuthenticated = true
        self.isSetup = true
        self.lastActivity = Date()
    }

    func authenticate(password: String) throws {
        guard let salt = UserDefaults.standard.data(forKey: saltKey),
              let encryptedVerification = loadFromKeychain(service: masterPasswordKey) else {
            throw SecurityError.authenticationFailed
        }

        let key = try EncryptionService.shared.deriveKey(password: password, salt: salt)

        let decrypted = try EncryptionService.shared.decrypt(encryptedVerification, using: key)
        guard String(data: decrypted, encoding: .utf8) == "verified" else {
            throw SecurityError.authenticationFailed
        }

        self.sessionKey = key
        self.isAuthenticated = true
        self.lastActivity = Date()
    }

    func authenticateWithBiometrics() {
        guard UserDefaults.standard.bool(forKey: useBiometricsKey) else { return }

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your Security Vault") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        if let storedPassword = self.getPasswordFromKeychain() {
                            do {
                                try self.authenticate(password: storedPassword)
                            } catch {
                                self.isAuthenticated = false
                            }
                        }
                    }
                }
            }
        }
    }

    func updateActivity() {
        lastActivity = Date()
    }

    private func setupAutoLockTimer() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAutoLock()
            }
            .store(in: &cancellables)
    }

    private func checkAutoLock() {
        guard isAuthenticated else { return }
        if Date().timeIntervalSince(lastActivity) > autoLockInterval {
            logout()
        }
    }

    func logout() {
        sessionKey = nil
        isAuthenticated = false
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(data: Data, service: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "user",
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain(service: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "user",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    private func savePasswordToKeychain(_ password: String) {
        if let data = password.data(using: .utf8) {
            saveToKeychain(data: data, service: "com.toolskit.security.password_fallback")
        }
    }

    private func getPasswordFromKeychain() -> String? {
        if let data = loadFromKeychain(service: "com.toolskit.security.password_fallback") {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
