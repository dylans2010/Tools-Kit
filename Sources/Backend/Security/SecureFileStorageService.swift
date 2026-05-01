import Foundation
import CryptoKit

/// Manages encrypted file storage on disk.
public final class SecureFileStorageService {
    public static let shared = SecureFileStorageService()

    private let fileManager = FileManager.default
    private var vaultDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("SecureVault", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    private init() {}

    /// Encrypts and saves a file to the secure vault directory.
    public func saveFile(data: Data, fileName: String, using key: SymmetricKey) throws -> String {
        let encryptedData = try EncryptionService.shared.encrypt(data, using: key)
        let fileId = UUID().uuidString
        let fileURL = vaultDirectory.appendingPathComponent(fileId)

        try encryptedData.write(to: fileURL, options: .atomic)
        return fileId
    }

    /// Loads and decrypts a file from the secure vault directory.
    public func loadFile(fileId: String, using key: SymmetricKey) throws -> Data {
        let fileURL = vaultDirectory.appendingPathComponent(fileId)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw SecurityError.itemNotFound
        }

        let encryptedData = try Data(contentsOf: fileURL)
        return try EncryptionService.shared.decrypt(encryptedData, using: key)
    }

    /// Deletes an encrypted file from disk.
    public func deleteFile(fileId: String) throws {
        let fileURL = vaultDirectory.appendingPathComponent(fileId)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// Purges all encrypted files in the vault directory.
    public func purgeAll() {
        try? fileManager.removeItem(at: vaultDirectory)
    }
}
