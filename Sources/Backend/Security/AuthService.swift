import Foundation
import Security
import LocalAuthentication
import CryptoKit

/// Manages vault authentication, biometric state, and the master encryption key.
public final class AuthService: ObservableObject {
    public static let shared = AuthService()

    @Published public var isAuthenticated = false
    @Published public var isBiometricsAvailable = false

    private var masterKey: SymmetricKey?
    private let context = LAContext()
    private let keychainService = "com.toolskit.security.auth"
    private let keychainAccount = "master_password_check"

    private init() {
        checkBiometrics()
    }

    /// Checks if biometrics (Face ID/Touch ID) are available on the device.
    public func checkBiometrics() {
        var error: NSError?
        isBiometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Sets the master password and stores a check value in the Keychain.
    public func setMasterPassword(_ password: String, config: SecurityConfig) throws {
        // Derive key to ensure password is valid and we can derive it
        let key = try EncryptionService.shared.deriveKey(password: password, salt: config.salt, rounds: config.keyDerivationRounds)

        // Store a "canary" value encrypted with this key to verify password later
        let canary = "authenticated".data(using: .utf8)!
        let encryptedCanary = try EncryptionService.shared.encrypt(canary, using: key)

        try saveToKeychain(data: encryptedCanary)
        self.masterKey = key
        self.isAuthenticated = true
    }

    /// Authenticates with master password.
    public func authenticate(password: String, config: SecurityConfig) throws {
        let encryptedCanary = try loadFromKeychain()
        let key = try EncryptionService.shared.deriveKey(password: password, salt: config.salt, rounds: config.keyDerivationRounds)

        do {
            let decryptedData = try EncryptionService.shared.decrypt(encryptedCanary, using: key)
            guard String(data: decryptedData, encoding: .utf8) == "authenticated" else {
                throw SecurityError.authenticationFailed
            }
            self.masterKey = key
            self.isAuthenticated = true
        } catch {
            throw SecurityError.authenticationFailed
        }
    }

    /// Authenticates using biometrics. Requires that master password has been previously set and we have access to it or a derived key.
    /// For simplicity in this implementation, we store a biometric-protected version of the master key material if biometrics are enabled.
    public func authenticateWithBiometrics() async -> Bool {
        guard isBiometricsAvailable else { return false }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your Secure Vault")
            if success {
                // In a production app, you'd retrieve a key from Keychain with .biometryCurrentSet access control.
                // For this system, we'll assume biometrics grants access to the session if already authenticated once or if key is in biometric keychain.
                // For demonstration, let's just update UI state if we can find the key.
                if let key = try? loadMasterKeyFromBiometricKeychain() {
                    self.masterKey = key
                    await MainActor.run { self.isAuthenticated = true }
                    return true
                }
            }
        } catch {
            return false
        }
        return false
    }

    /// Provides the active master key for encryption/decryption operations.
    public func getMasterKey() throws -> SymmetricKey {
        guard let key = masterKey, isAuthenticated else {
            throw SecurityError.vaultLocked
        }
        return key
    }

    public func lock() {
        masterKey = nil
        isAuthenticated = false
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw SecurityError.encryptionFailed }
    }

    private func loadFromKeychain() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw SecurityError.authenticationFailed
        }
        return data
    }

    // Simplified biometric key persistence for demo purposes
    public func enableBiometricAccess(password: String, config: SecurityConfig) throws {
        let key = try EncryptionService.shared.deriveKey(password: password, salt: config.salt, rounds: config.keyDerivationRounds)
        let keyData = key.withUnsafeBytes { Data($0) }

        let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .biometryAny, nil)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(keychainService).biometric",
            kSecAttrAccount as String: "master_key",
            kSecValueData as String: keyData,
            kSecAttrAccessControl as String: access as Any
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadMasterKeyFromBiometricKeychain() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(keychainService).biometric",
            kSecAttrAccount as String: "master_key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseOperationPrompt as String: "Unlock Vault with Biometrics"
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw SecurityError.authenticationFailed
        }
        return SymmetricKey(data: data)
    }
}
