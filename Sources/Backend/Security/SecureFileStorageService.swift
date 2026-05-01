import Foundation
import CryptoKit

class SecureFileStorageService {
    static let shared = SecureFileStorageService()

    private let fileManager = FileManager.default
    private let vaultDirectoryName = "SecurityVault"

    private init() {
        createVaultDirectory()
    }

    private var vaultURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(vaultDirectoryName)
    }

    private func createVaultDirectory() {
        if !fileManager.fileExists(atPath: vaultURL.path) {
            try? fileManager.createDirectory(at: vaultURL, withIntermediateDirectories: true)
        }
    }

    func saveEncryptedFile(data: Data, filename: String, key: SymmetricKey) throws -> String {
        let encryptedData = try EncryptionService.shared.encrypt(data, using: key)
        let fileURL = vaultURL.appendingPathComponent(filename)
        try encryptedData.write(to: fileURL, options: .atomic)
        return filename
    }

    func loadDecryptedFile(filename: String, key: SymmetricKey) throws -> Data {
        let fileURL = vaultURL.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw SecurityError.itemNotFound
        }
        let encryptedData = try Data(contentsOf: fileURL)
        return try EncryptionService.shared.decrypt(encryptedData, using: key)
    }

    func deleteFile(filename: String) {
        let fileURL = vaultURL.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
    }

    func clearAll() {
        try? fileManager.removeItem(at: vaultURL)
        createVaultDirectory()
    }

    func getVaultFiles() -> [URL] {
        return (try? fileManager.contentsOfDirectory(at: vaultURL, includingPropertiesForKeys: nil)) ?? []
    }
}
