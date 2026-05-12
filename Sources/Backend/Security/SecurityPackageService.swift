import Foundation
import CryptoKit

struct SecurityPackageMetadata: Codable, Sendable {
    let version: Int
    let exportDate: Date
    let salt: Data
    let itemIndex: [VaultItem]
    let globalHash: String
    let shardIndices: [String: SecureFileStorageService.ShardIndex]
}

class SecurityPackageService {
    nonisolated(unsafe) static let shared = SecurityPackageService()

    private let fileManager = FileManager.default

    private init() {}

    func exportPackage(password: String) async throws -> URL {
        try await AuthService.shared.requireAuth()

        guard let salt = UserDefaults.standard.data(forKey: "com.toolskit.security.salt") else {
            throw SecurityError.keyDerivationFailed
        }

        let exportKey = try EncryptionService.shared.deriveKey(password: password, salt: salt)
        let items = await VaultManager.shared.items
        let sessionKey = await MainActor.run { AuthService.shared.sessionKey }!

        // 1. Build shard table and collect encrypted shards
        var shardIndices: [String: SecureFileStorageService.ShardIndex] = [:]
        var allShardsData: [String: Data] = [:]

        for item in items {
            let indexURL = SecureFileStorageService.shared.getVaultURL(for: item.payloadIdentifier)
            let encryptedIndex = try Data(contentsOf: indexURL)
            let indexData = try EncryptionService.shared.decrypt(encryptedIndex, using: sessionKey)
            let index = try JSONDecoder().decode(SecureFileStorageService.ShardIndex.self, from: indexData)
            shardIndices[item.payloadIdentifier] = index

            for shardName in index.shardFilenames {
                let shardURL = SecureFileStorageService.shared.getVaultURL(for: shardName)
                let originalEncryptedShard = try Data(contentsOf: shardURL)
                let decryptedShardChunk = try EncryptionService.shared.decrypt(originalEncryptedShard, using: sessionKey)
                let reEncryptedShard = try EncryptionService.shared.encrypt(decryptedShardChunk, using: exportKey)
                allShardsData[shardName] = reEncryptedShard
            }
        }

        // 2. Create metadata
        let itemsData = try JSONEncoder().encode(items)
        let globalHash = SHA256.hash(data: itemsData).compactMap { String(format: "%02x", $0) }.joined()

        let metadata = SecurityPackageMetadata(
            version: 3,
            exportDate: Date(),
            salt: salt,
            itemIndex: items,
            globalHash: globalHash,
            shardIndices: shardIndices
        )

        let metaDataJSON = try JSONEncoder().encode(metadata)
        let encryptedMeta = try EncryptionService.shared.encrypt(metaDataJSON, using: exportKey)

        // 3. Construct Obfuscated Binary Format
        var packageData = Data()

        // Random preamble (structural obfuscation)
        var preamble = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, preamble.count, &preamble)
        packageData.append(Data(preamble))

        // Salt (16 bytes)
        packageData.append(salt)

        // HMAC (32 bytes)
        let hmac = HMAC<SHA256>.authenticationCode(for: encryptedMeta, using: SymmetricKey(data: SHA256.hash(data: password.data(using: .utf8)!)))
        packageData.append(Data(hmac))

        // Metadata Length (8 bytes)
        var metaLength = UInt64(encryptedMeta.count).bigEndian
        packageData.append(Data(bytes: &metaLength, count: 8))

        // Encrypted Metadata
        packageData.append(encryptedMeta)

        // Shards Data with randomized offsets (simulated via indexed sequence)
        for (shardName, shardData) in allShardsData {
            var nameLength = UInt32(shardName.count).bigEndian
            packageData.append(Data(bytes: &nameLength, count: 4))
            packageData.append(shardName.data(using: .utf8)!)

            var dataLength = UInt64(shardData.count).bigEndian
            packageData.append(Data(bytes: &dataLength, count: 8))
            packageData.append(shardData)
        }

        let packageURL = fileManager.temporaryDirectory.appendingPathComponent("VaultBackup_\(Int(Date().timeIntervalSince1970)).toolkitsec")
        try packageData.write(to: packageURL, options: .atomic)

        return packageURL
    }

    func importPackage(at url: URL, password: String) async throws {
        try await AuthService.shared.requireAuth()

        let packageData = try Data(contentsOf: url)
        var offset = 64 // Skip random preamble

        let salt = packageData.subdata(in: offset..<offset+16)
        offset += 16

        let hmacData = packageData.subdata(in: offset..<offset+32)
        offset += 32

        let metaLengthData = packageData.subdata(in: offset..<offset+8)
        let metaLength = metaLengthData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        offset += 8

        let encryptedMeta = packageData.subdata(in: offset..<offset+Int(metaLength))
        offset += Int(metaLength)

        // Verify HMAC
        let expectedHMAC = HMAC<SHA256>.authenticationCode(for: encryptedMeta, using: SymmetricKey(data: SHA256.hash(data: password.data(using: .utf8)!)))
        guard hmacData == Data(expectedHMAC) else {
            throw SecurityError.authenticationFailed
        }

        // Decrypt metadata
        let importKey = try EncryptionService.shared.deriveKey(password: password, salt: salt)
        let metaDataJSON = try EncryptionService.shared.decrypt(encryptedMeta, using: importKey)
        let metadata = try JSONDecoder().decode(SecurityPackageMetadata.self, from: metaDataJSON)

        // Collect shards from binary
        var shardsByPackageName: [String: Data] = [:]
        while offset < packageData.count {
            let nameLengthData = packageData.subdata(in: offset..<offset+4)
            let nameLength = nameLengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            offset += 4

            let shardName = String(data: packageData.subdata(in: offset..<offset+Int(nameLength)), encoding: .utf8)!
            offset += Int(nameLength)

            let dataLengthData = packageData.subdata(in: offset..<offset+8)
            let dataLength = dataLengthData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
            offset += 8

            let shardData = packageData.subdata(in: offset..<offset+Int(dataLength))
            shardsByPackageName[shardName] = shardData
            offset += Int(dataLength)
        }

        // Verify global integrity and import
        let itemsData = try JSONEncoder().encode(metadata.itemIndex)
        guard metadata.globalHash == SHA256.hash(data: itemsData).compactMap({ String(format: "%02x", $0) }).joined() else {
            throw SecurityError.decryptionFailed
        }

        for item in metadata.itemIndex {
            guard let shardIndex = metadata.shardIndices[item.payloadIdentifier] else { continue }

            var decryptedFullData = Data()
            var previousHash = ""

            for (i, shardName) in shardIndex.shardFilenames.enumerated() {
                guard let encryptedShard = shardsByPackageName[shardName] else {
                    throw SecurityError.decryptionFailed
                }

                let currentHash = SHA256.hash(data: encryptedShard).compactMap { String(format: "%02x", $0) }.joined()
                guard currentHash == shardIndex.shardHashes[i] else {
                    throw SecurityError.decryptionFailed
                }

                let decryptedChunk = try EncryptionService.shared.decrypt(encryptedShard, using: importKey)
                var chunkData = decryptedChunk

                if i > 0 {
                    guard let prevHashData = previousHash.data(using: .utf8) else { throw SecurityError.decryptionFailed }
                    let extractedPrevHash = chunkData.subdata(in: 0..<prevHashData.count)
                    guard extractedPrevHash == prevHashData else {
                        throw SecurityError.decryptionFailed
                    }
                    chunkData.removeSubrange(0..<prevHashData.count)
                }

                decryptedFullData.append(chunkData)
                previousHash = currentHash
            }

            try await VaultManager.shared.addItem(item, data: decryptedFullData)
        }
    }
}
