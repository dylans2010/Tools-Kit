import Foundation
import Combine
import CryptoKit

/// The central manager for vault items, persistence, and state.
@MainActor
public final class VaultManager: ObservableObject {
    public static let shared = VaultManager()

    @Published public var items: [VaultItem] = []
    @Published public var config = SecurityConfig()
    @Published public var isLoading = false

    private let persistence = WorkspacePersistence.shared
    private let configFilename = "security_config.json"
    private let indexFilename = "vault_index.json"

    private init() {
        loadConfig()
    }

    // MARK: - Lifecycle

    public func initializeVault(password: String, useBiometrics: Bool) throws {
        let salt = EncryptionService.shared.generateSalt()
        let rounds = 100000

        let newConfig = SecurityConfig(
            isMasterPasswordSet: true,
            useBiometrics: useBiometrics,
            salt: salt,
            keyDerivationRounds: rounds
        )

        try VaultAuthService.shared.setMasterPassword(password, config: newConfig)
        if useBiometrics {
            try? VaultAuthService.shared.enableBiometricAccess(password: password, config: newConfig)
        }

        self.config = newConfig
        try saveConfig()
        try saveItems()
    }

    public func loadVault() async throws {
        isLoading = true
        defer { isLoading = false }

        // Items are stored in an encrypted index file.
        // We need the master key to decrypt it.
        let key = try VaultAuthService.shared.getMasterKey()

        if persistence.exists(filename: indexFilename) {
            let encryptedData = try persistence.load(Data.self, from: indexFilename)
            let decryptedData = try EncryptionService.shared.decrypt(encryptedData, using: key)
            self.items = try JSONDecoder().decode([VaultItem].self, from: decryptedData)
        }
    }

    // MARK: - Item Management

    public func addItem(_ item: VaultItem, data: Data? = nil) async throws {
        var newItem = item
        let key = try VaultAuthService.shared.getMasterKey()

        if let data = data {
            if data.count < 1024 * 64 { // If less than 64KB, store in payload
                newItem.encryptedPayload = try EncryptionService.shared.encrypt(data, using: key)
            } else { // Store as file
                let fileId = try SecureFileStorageService.shared.saveFile(data: data, fileName: item.title, using: key)
                newItem.fileReference = fileId
            }
        }

        items.append(newItem)
        try saveItems()
    }

    public func deleteItem(_ item: VaultItem) async throws {
        if let fileId = item.fileReference {
            try SecureFileStorageService.shared.deleteFile(fileId: fileId)
        }
        items.removeAll { $0.id == item.id }
        try saveItems()
    }

    public func getItemData(_ item: VaultItem) throws -> Data? {
        let key = try VaultAuthService.shared.getMasterKey()

        if let payload = item.encryptedPayload {
            return try EncryptionService.shared.decrypt(payload, using: key)
        } else if let fileId = item.fileReference {
            return try SecureFileStorageService.shared.loadFile(fileId: fileId, using: key)
        }
        return nil
    }

    // MARK: - Persistence

    private func loadConfig() {
        if persistence.exists(filename: configFilename) {
            self.config = (try? persistence.load(SecurityConfig.self, from: configFilename)) ?? SecurityConfig()
        }
    }

    private func saveConfig() throws {
        try persistence.save(config, to: configFilename)
    }

    private func saveItems() throws {
        let key = try VaultAuthService.shared.getMasterKey()
        let data = try JSONEncoder().encode(items)
        let encryptedData = try EncryptionService.shared.encrypt(data, using: key)
        try persistence.save(encryptedData, to: indexFilename)
    }
}
