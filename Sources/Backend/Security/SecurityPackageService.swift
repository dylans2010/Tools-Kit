import Foundation
import CryptoKit
import ZIPFoundation

struct SecurityPackageMetadata: Codable {
    let version: Int
    let exportDate: Date
    let salt: Data
    let itemIndex: [VaultItem]
    let integrityHash: String
}

class SecurityPackageService {
    static let shared = SecurityPackageService()

    private let fileManager = FileManager.default

    private init() {}

    func exportPackage(password: String) async throws -> URL {
        guard let salt = UserDefaults.standard.data(forKey: "com.toolskit.security.salt") else {
            throw SecurityError.keyDerivationFailed
        }

        let exportKey = try EncryptionService.shared.deriveKey(password: password, salt: salt)
        let items = await VaultManager.shared.items

        // 1. Create temporary working directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let vaultFilesDir = tempDir.appendingPathComponent("vault_files")
        try fileManager.createDirectory(at: vaultFilesDir, withIntermediateDirectories: true)

        // 2. Copy and re-encrypt files for the package (or just copy since they are already encrypted)
        // For security, we'll keep them encrypted with the SAME master password key.
        // The package will be a ZIP of these files + metadata.

        for item in items {
            let itemData = try await VaultManager.shared.loadItemData(item)
            // Re-encrypt specifically for package if needed, but here we'll use the same scheme
            let encrypted = try EncryptionService.shared.encrypt(itemData, using: exportKey)
            try encrypted.write(to: vaultFilesDir.appendingPathComponent(item.payloadIdentifier))
        }

        // 3. Create metadata
        let indexData = try JSONEncoder().encode(items)
        let hash = SHA256.hash(data: indexData).compactMap { String(format: "%02x", $0) }.joined()

        let metadata = SecurityPackageMetadata(
            version: 1,
            exportDate: Date(),
            salt: salt,
            itemIndex: items,
            integrityHash: hash
        )

        let metaData = try JSONEncoder().encode(metadata)
        try metaData.write(to: tempDir.appendingPathComponent("metadata.json"))

        // 4. ZIP everything
        let packageURL = fileManager.temporaryDirectory.appendingPathComponent("VaultBackup_\(Int(Date().timeIntervalSince1970)).toolkitsec")

        try fileManager.zipItem(at: tempDir, to: packageURL)

        // Cleanup temp
        try? fileManager.removeItem(at: tempDir)

        return packageURL
    }

    func importPackage(at url: URL, password: String) async throws {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // 1. Unzip
        try fileManager.unzipItem(at: url, to: tempDir)

        // 2. Read metadata
        let metaURL = tempDir.appendingPathComponent("metadata.json")
        let metaData = try Data(contentsOf: metaURL)
        let metadata = try JSONDecoder().decode(SecurityPackageMetadata.self, from: metaData)

        // 3. Verify integrity
        let indexData = try JSONEncoder().encode(metadata.itemIndex)
        let currentHash = SHA256.hash(data: indexData).compactMap { String(format: "%02x", $0) }.joined()

        guard currentHash == metadata.integrityHash else {
            throw SecurityError.decryptionFailed // Integrity failure
        }

        // 4. Derive key using package salt
        let importKey = try EncryptionService.shared.deriveKey(password: password, salt: metadata.salt)

        // 5. Verify password by trying to decrypt first item
        if let firstItem = metadata.itemIndex.first {
            let fileURL = tempDir.appendingPathComponent("vault_files").appendingPathComponent(firstItem.payloadIdentifier)
            let encryptedData = try Data(contentsOf: fileURL)
            _ = try EncryptionService.shared.decrypt(encryptedData, using: importKey)
        }

        // 6. Import items into local vault
        for item in metadata.itemIndex {
            let fileURL = tempDir.appendingPathComponent("vault_files").appendingPathComponent(item.payloadIdentifier)
            let encryptedData = try Data(contentsOf: fileURL)
            let decryptedData = try EncryptionService.shared.decrypt(encryptedData, using: importKey)

            try await VaultManager.shared.addItem(item, data: decryptedData)
        }

        // Cleanup
        try? fileManager.removeItem(at: tempDir)
    }
}
