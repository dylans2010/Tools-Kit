import Foundation
import Combine
import CryptoKit

@MainActor
class VaultManager: ObservableObject {
    static let shared = VaultManager()

    @Published var items: [VaultItem] = []
    @Published var isLoading = false

    private let indexKey = "com.toolskit.security.vault.index"

    private init() {
        loadIndex()
    }

    func loadIndex() {
        guard let key = AuthService.shared.sessionKey,
              let encryptedData = UserDefaults.standard.data(forKey: indexKey) else {
            self.items = []
            return
        }

        do {
            let decryptedData = try EncryptionService.shared.decrypt(encryptedData, using: key)
            let decoded = try JSONDecoder().decode([VaultItem].self, from: decryptedData)
            self.items = decoded
        } catch {
            self.items = []
        }
    }

    func saveIndex() {
        guard let key = AuthService.shared.sessionKey else { return }

        if let encoded = try? JSONEncoder().encode(items) {
            if let encrypted = try? EncryptionService.shared.encrypt(encoded, using: key) {
                UserDefaults.standard.set(encrypted, forKey: indexKey)
            }
        }
    }

    // MARK: - CRUD Operations

    func addItem(_ item: VaultItem, data: Data) throws {
        guard let key = AuthService.shared.sessionKey else { throw SecurityError.authenticationFailed }

        let filename = try SecureFileStorageService.shared.saveEncryptedFile(data: data, filename: "\(item.id.uuidString).vault", key: key)

        var newItem = item
        newItem.payloadIdentifier = filename
        items.append(newItem)
        saveIndex()
    }

    func updateItem(_ item: VaultItem, data: Data? = nil) throws {
        guard let key = AuthService.shared.sessionKey else { throw SecurityError.authenticationFailed }

        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = item
            updatedItem.updatedAt = Date()

            if let data = data {
                let filename = try SecureFileStorageService.shared.saveEncryptedFile(data: data, filename: "\(item.id.uuidString).vault", key: key)
                updatedItem.payloadIdentifier = filename
            }

            items[idx] = updatedItem
            saveIndex()
        }
    }

    func deleteItem(_ item: VaultItem) {
        SecureFileStorageService.shared.deleteFile(filename: item.payloadIdentifier)
        items.removeAll { $0.id == item.id }
        saveIndex()
    }

    func loadItemData(_ item: VaultItem) async throws -> Data {
        try await AuthService.shared.requireAuth()
        guard let key = AuthService.shared.sessionKey else { throw SecurityError.authenticationFailed }
        return try SecureFileStorageService.shared.loadDecryptedFile(filename: item.payloadIdentifier, key: key)
    }

    // MARK: - Helpers

    func items(for category: VaultCategory) -> [VaultItem] {
        items.filter { $0.category == category }
    }
}
