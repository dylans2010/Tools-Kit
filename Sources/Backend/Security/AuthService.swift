import Foundation
import LocalAuthentication
import CryptoKit
import Combine
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var isSetup = false
    @Published var lastActivity: Date = Date()
    @Published var logs: [SecurityLogEvent] = []

    private let masterPasswordKey = "com.toolskit.security.master"
    private let saltKey = "com.toolskit.security.salt"
    private let useBiometricsKey = "com.toolskit.security.useBiometrics"
    private let wrappedVMKKey = "com.toolskit.security.wrapped_vmk"
    private let wrappedDEKKey = "com.toolskit.security.wrapped_dek"
    private let vmkSecureEnclaveTag = "com.toolskit.security.vmk"
    private let autoLockInterval: TimeInterval = 300 // 5 minutes

    var sessionKey: SymmetricKey? // This acts as the DEK (Data Encryption Key)
    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkSetup()
        setupAutoLockTimer()
        loadLogs()
    }

    func checkSetup() {
        isSetup = UserDefaults.standard.data(forKey: saltKey) != nil
    }

    func logEvent(type: SecurityLogEvent.LogType, message: String) {
        let event = SecurityLogEvent(id: UUID(), type: type, message: message, timestamp: Date())
        logs.insert(event, at: 0)
        saveLogs()
    }

    private func saveLogs() {
        try? WorkspacePersistence.shared.save(logs, to: "security_logs.json")
    }

    private func loadLogs() {
        logs = (try? WorkspacePersistence.shared.load([SecurityLogEvent].self, from: "security_logs.json")) ?? []
    }

    func setup(password: String, useBiometrics: Bool) throws {
        let salt = EncryptionService.shared.generateSalt()
        let vmk = try EncryptionService.shared.deriveKey(password: password, salt: salt)

        // Generate DEK
        let dek = EncryptionService.shared.generateRandomKey()
        let wrappedDEK = try EncryptionService.shared.wrapKey(dek, using: vmk)

        UserDefaults.standard.set(salt, forKey: saltKey)
        UserDefaults.standard.set(useBiometrics, forKey: useBiometricsKey)
        UserDefaults.standard.set(wrappedDEK, forKey: wrappedDEKKey)

        let verification = "verified".data(using: .utf8)!
        let encrypted = try EncryptionService.shared.encrypt(verification, using: vmk)

        saveToKeychain(data: encrypted, service: masterPasswordKey)

        if useBiometrics {
            let seKey = try createSecureEnclaveKey()
            guard let publicKey = SecKeyCopyPublicKey(seKey) else { throw SecurityError.encryptionFailed }

            // Wrap VMK with SE Key
            let vmkData = vmk.withUnsafeBytes { Data($0) }
            let wrappedVMK = try EncryptionService.shared.encryptWithSecureEnclave(vmkData, publicKey: publicKey)
            UserDefaults.standard.set(wrappedVMK, forKey: wrappedVMKKey)
        }

        self.sessionKey = dek
        self.isAuthenticated = true
        self.isSetup = true
        self.lastActivity = Date()
        logEvent(type: .settingsChange, message: "Vault initialized and first login")
    }

    func authenticate(password: String) throws {
        guard let salt = UserDefaults.standard.data(forKey: saltKey),
              let wrappedDEK = UserDefaults.standard.data(forKey: wrappedDEKKey),
              let encryptedVerification = loadFromKeychain(service: masterPasswordKey) else {
            throw SecurityError.authenticationFailed
        }

        let vmk = try EncryptionService.shared.deriveKey(password: password, salt: salt)

        let decrypted = try EncryptionService.shared.decrypt(encryptedVerification, using: vmk)
        guard String(data: decrypted, encoding: .utf8) == "verified" else {
            throw SecurityError.authenticationFailed
        }

        let dek = try EncryptionService.shared.unwrapKey(wrappedDEK, using: vmk)

        self.sessionKey = dek
        self.isAuthenticated = true
        self.lastActivity = Date()
        logEvent(type: .login, message: "Successful password login")
    }

    func authenticateWithBiometrics(completion: ((Bool) -> Void)? = nil) {
        guard UserDefaults.standard.bool(forKey: useBiometricsKey) else {
            completion?(false)
            return
        }

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your Security Vault") { success, authenticationError in
                Task { @MainActor in
                    if success {
                        do {
                            try self.unlockWithSecureEnclave()
                            self.logEvent(type: .login, message: "Successful biometric login")
                            completion?(true)
                        } catch {
                            self.isAuthenticated = false
                            self.logEvent(type: .failedLogin, message: "Biometric login failed during decryption")
                            completion?(false)
                        }
                    } else {
                        self.logEvent(type: .failedLogin, message: "Biometric authentication failed")
                        completion?(false)
                    }
                }
            }
        } else {
            completion?(false)
        }
    }

    // MARK: - Secure Enclave Integration

    private func createSecureEnclaveKey() throws -> SecKey {
        guard SecureEnclave.isAvailable else { throw SecurityError.secureEnclaveNotAvailable }

        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.biometryCurrentSet, .userPresence],
            nil
        )!

        let tag = vmkSecureEnclaveTag.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: tag,
                kSecAttrAccessControl: accessControl
            ]
        ]

        SecItemDelete(query as CFDictionary)
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(query as CFDictionary, &error) else {
            throw SecurityError.encryptionFailed
        }
        return key
    }

    private func unlockWithSecureEnclave() throws {
        guard let wrappedVMK = UserDefaults.standard.data(forKey: wrappedVMKKey),
              let wrappedDEK = UserDefaults.standard.data(forKey: wrappedDEKKey) else {
            throw SecurityError.authenticationFailed
        }

        let tag = vmkSecureEnclaveTag.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef: true
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let seKey = item as! SecKey? else {
            throw SecurityError.hardwareAuthFailed
        }

        // Unwrap VMK using Secure Enclave Key
        let vmkData = try EncryptionService.shared.decryptWithSecureEnclave(wrappedVMK, privateKey: seKey)
        let vmk = SymmetricKey(data: vmkData)

        // Unwrap DEK using VMK
        let dek = try EncryptionService.shared.unwrapKey(wrappedDEK, using: vmk)

        self.sessionKey = dek
        self.isAuthenticated = true
        self.lastActivity = Date()
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

        #if canImport(UIKit)
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.logout()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.updateActivity()
            }
            .store(in: &cancellables)
        #endif
    }

    private func checkAutoLock() {
        guard isAuthenticated else { return }
        if Date().timeIntervalSince(lastActivity) > autoLockInterval {
            logout()
        }
    }

    @MainActor
    func requireAuth() async throws {
        if !isAuthenticated {
            // This would normally trigger a UI prompt if not authenticated,
            // but here we ensure that whatever operation is being performed
            // is gated by the current auth state.
            throw SecurityError.authenticationFailed
        }

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Confirm your identity to access sensitive data")
            if !success {
                throw SecurityError.hardwareAuthFailed
            }
            updateActivity()
        } else {
            throw SecurityError.secureEnclaveNotAvailable
        }
    }

    func logout() {
        // Zero out session key memory
        if let key = sessionKey {
            key.withUnsafeBytes { ptr in
                let mutablePtr = UnsafeMutableRawBufferPointer(mutating: ptr)
                mutablePtr.initializeMemory(as: UInt8.self, repeating: 0)
            }
        }
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


    func resetVaultAndPassword() {
        logout()

        UserDefaults.standard.removeObject(forKey: saltKey)
        UserDefaults.standard.removeObject(forKey: useBiometricsKey)
        UserDefaults.standard.removeObject(forKey: wrappedVMKKey)
        UserDefaults.standard.removeObject(forKey: wrappedDEKKey)
        UserDefaults.standard.removeObject(forKey: "com.toolskit.security.vault.index")

        let tag = vmkSecureEnclaveTag.data(using: .utf8)!
        let keyQuery: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom
        ]
        SecItemDelete(keyQuery as CFDictionary)

        let passwordQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: masterPasswordKey,
            kSecAttrAccount: "user"
        ]
        SecItemDelete(passwordQuery as CFDictionary)

        SecureFileStorageService.shared.clearAll()
        VaultManager.shared.items = []
        isSetup = false
        logEvent(type: .settingsChange, message: "Vault reset and password removed")
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
