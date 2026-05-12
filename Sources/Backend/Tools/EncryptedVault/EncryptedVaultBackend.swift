import Foundation
import Security

struct VaultEntry: Identifiable, Codable, Sendable {
    let id: String
    var label: String
    var category: VaultCategory
    let createdAt: Date
    var updatedAt: Date

    enum VaultCategory: String, CaseIterable, Codable, Identifiable, Sendable {
        case password = "Password"
        case token = "Token"
        case note = "Note"
        case creditCard = "Card"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .password: return "key.fill"
            case .token: return "lock.shield.fill"
            case .note: return "note.text"
            case .creditCard: return "creditcard.fill"
            }
        }
    }
}

@MainActor
final class EncryptedVaultBackend: ObservableObject {
    @Published var entries: [VaultEntry] = []
    @Published var errorMessage = ""

    private let service = "com.toolskit.encryptedvault"

    init() {
        loadEntries()
    }

    func addEntry(label: String, secret: String, category: VaultEntry.VaultCategory) {
        let id = UUID().uuidString
        let entry = VaultEntry(id: id, label: label, category: category, createdAt: Date(), updatedAt: Date())
        guard saveToKeychain(account: id, secret: secret) else {
            errorMessage = "Failed to save to Keychain"
            return
        }
        entries.insert(entry, at: 0)
        persistIndex()
    }

    func secret(for entry: VaultEntry) -> String? {
        loadFromKeychain(account: entry.id)
    }

    func deleteEntry(_ entry: VaultEntry) {
        deleteFromKeychain(account: entry.id)
        entries.removeAll { $0.id == entry.id }
        persistIndex()
    }

    func updateEntry(_ entry: VaultEntry, newSecret: String) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entry
            updated.updatedAt = Date()
            entries[idx] = updated
            _ = saveToKeychain(account: entry.id, secret: newSecret)
            persistIndex()
        }
    }

    private func saveToKeychain(account: String, secret: String) -> Bool {
        guard let data = secret.data(using: .utf8) else { return false }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func loadFromKeychain(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteFromKeychain(account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func persistIndex() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "encryptedVaultIndex")
        }
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: "encryptedVaultIndex"),
              let decoded = try? JSONDecoder().decode([VaultEntry].self, from: data) else { return }
        entries = decoded
    }
}
