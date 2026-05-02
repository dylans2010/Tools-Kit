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

    private let shardSize = 256 * 1024 // 256KB shards

    struct ShardIndex: Codable {
        let originalFilename: String
        let shardFilenames: [String]
        let shardHashes: [String]
        let totalSize: Int
    }

    func saveEncryptedFile(data: Data, filename: String, key: SymmetricKey) throws -> String {
        let totalSize = data.count
        var shardFilenames: [String] = []
        var shardHashes: [String] = []
        var previousHash = ""

        var offset = 0
        while offset < totalSize {
            let length = min(shardSize, totalSize - offset)
            var chunk = data.subdata(in: offset..<(offset + length))

            // Integrity chain: prepend previous hash
            if let prevHashData = previousHash.data(using: .utf8) {
                chunk.insert(contentsOf: prevHashData, at: 0)
            }

            let encryptedShard = try EncryptionService.shared.encrypt(chunk, using: key)
            let shardName = UUID().uuidString + ".shard"
            let shardURL = vaultURL.appendingPathComponent(shardName)
            try encryptedShard.write(to: shardURL, options: .atomic)

            shardFilenames.append(shardName)
            let currentHash = SHA256.hash(data: encryptedShard).compactMap { String(format: "%02x", $0) }.joined()
            shardHashes.append(currentHash)
            previousHash = currentHash

            offset += length
        }

        let index = ShardIndex(originalFilename: filename, shardFilenames: shardFilenames, shardHashes: shardHashes, totalSize: totalSize)
        let indexData = try JSONEncoder().encode(index)
        let encryptedIndex = try EncryptionService.shared.encrypt(indexData, using: key)
        let indexFilename = filename + ".index"
        try encryptedIndex.write(to: vaultURL.appendingPathComponent(indexFilename), options: .atomic)

        return indexFilename
    }

    func loadDecryptedFile(filename: String, key: SymmetricKey) throws -> Data {
        let indexURL = vaultURL.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: indexURL.path) else {
            throw SecurityError.itemNotFound
        }

        let encryptedIndex = try Data(contentsOf: indexURL)
        let indexData = try EncryptionService.shared.decrypt(encryptedIndex, using: key)
        let index = try JSONDecoder().decode(ShardIndex.self, from: indexData)

        var decryptedFile = Data()
        var previousHash = ""

        for (i, shardName) in index.shardFilenames.enumerated() {
            let shardURL = vaultURL.appendingPathComponent(shardName)
            let encryptedShard = try Data(contentsOf: shardURL)

            // Verify shard integrity
            let currentHash = SHA256.hash(data: encryptedShard).compactMap { String(format: "%02x", $0) }.joined()
            guard currentHash == index.shardHashes[i] else {
                throw SecurityError.decryptionFailed
            }

            let decryptedChunk = try EncryptionService.shared.decrypt(encryptedShard, using: key)

            var chunkData = decryptedChunk
            if i > 0 {
                // Verify integrity chain
                guard let prevHashData = previousHash.data(using: .utf8) else { throw SecurityError.decryptionFailed }
                let extractedPrevHash = chunkData.subdata(in: 0..<prevHashData.count)
                guard extractedPrevHash == prevHashData else {
                    throw SecurityError.decryptionFailed
                }
                chunkData.removeSubrange(0..<prevHashData.count)
            }

            decryptedFile.append(chunkData)
            previousHash = currentHash
        }

        return decryptedFile
    }

    func deleteFile(filename: String) {
        let indexURL = vaultURL.appendingPathComponent(filename)
        if let encryptedIndex = try? Data(contentsOf: indexURL),
           let key = AuthService.shared.sessionKey,
           let indexData = try? EncryptionService.shared.decrypt(encryptedIndex, using: key),
           let index = try? JSONDecoder().decode(ShardIndex.self, from: indexData) {
            for shardName in index.shardFilenames {
                let shardURL = vaultURL.appendingPathComponent(shardName)
                try? fileManager.removeItem(at: shardURL)
            }
        }
        try? fileManager.removeItem(at: indexURL)
    }

    func clearAll() {
        try? fileManager.removeItem(at: vaultURL)
        createVaultDirectory()
    }

    func getVaultFiles() -> [URL] {
        return (try? fileManager.contentsOfDirectory(at: vaultURL, includingPropertiesForKeys: nil)) ?? []
    }

    func getVaultURL(for filename: String) -> URL {
        return vaultURL.appendingPathComponent(filename)
    }
}
