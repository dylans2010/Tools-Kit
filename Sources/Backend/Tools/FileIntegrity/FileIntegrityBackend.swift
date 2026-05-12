import Foundation
import CommonCrypto
import CryptoKit

struct FileHashRecord: Identifiable, Codable, Sendable {
    let id: UUID
    let fileName: String
    let filePath: String
    let sha256: String
    let fileSize: Int64
    let recordedAt: Date
    var lastVerified: Date?
    var tampered: Bool?
}

@MainActor
final class FileIntegrityBackend: ObservableObject {
    @Published var records: [FileHashRecord] = []
    @Published var isProcessing = false
    @Published var currentSHA256 = ""
    @Published var currentMD5 = ""
    @Published var currentSHA1 = ""
    @Published var currentFileName = ""
    @Published var statusMessage = ""

    private let storageKey = "fileIntegrityRecords"

    init() { loadRecords() }

    func processFile(url: URL) {
        isProcessing = true
        statusMessage = "Hashing..."
        Task {
            guard url.startAccessingSecurityScopedResource() else {
                statusMessage = "Permission denied"
                isProcessing = false
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                currentSHA256 = data.sha256Hex
                currentMD5 = data.md5Hex
                currentSHA1 = data.sha1Hex
                currentFileName = url.lastPathComponent
                statusMessage = "Hashed \(url.lastPathComponent)"
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
            isProcessing = false
        }
    }

    func saveRecord(url: URL) {
        guard !currentSHA256.isEmpty else { return }
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = attrs?[.size] as? Int64 ?? 0
        let record = FileHashRecord(
            id: UUID(), fileName: currentFileName, filePath: url.path,
            sha256: currentSHA256, fileSize: size, recordedAt: Date()
        )
        records.insert(record, at: 0)
        saveRecords()
        statusMessage = "Record saved"
    }

    func verify(record: FileHashRecord) {
        let url = URL(fileURLWithPath: record.filePath)
        isProcessing = true
        Task {
            do {
                let data = try Data(contentsOf: url)
                let newHash = data.sha256Hex
                let tampered = newHash != record.sha256
                if let idx = records.firstIndex(where: { $0.id == record.id }) {
                    records[idx].lastVerified = Date()
                    records[idx].tampered = tampered
                }
                saveRecords()
                statusMessage = tampered ? "⚠️ File has been modified!" : "✓ File integrity verified"
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
            isProcessing = false
        }
    }

    func deleteRecord(_ record: FileHashRecord) {
        records.removeAll { $0.id == record.id }
        saveRecords()
    }

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode([FileHashRecord].self, from: data) {
            records = loaded
        }
    }
}

private extension Data {
    var sha256Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(count), &digest) }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    var md5Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        withUnsafeBytes { _ = CC_MD5($0.baseAddress, CC_LONG(count), &digest) }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    var sha1Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        withUnsafeBytes { _ = CC_SHA1($0.baseAddress, CC_LONG(count), &digest) }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
