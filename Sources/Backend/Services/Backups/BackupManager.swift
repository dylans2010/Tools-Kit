import Foundation
import ZIPFoundation
import UIKit
import CryptoKit

struct BackupMetadata: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let appVersion: String
    let buildNumber: String
    let deviceInfo: String
    let osVersion: String
    var totalSizeCompressed: Int64
    let totalSizeRaw: Int64
    let moduleSizes: [String: Int64]
    let moduleFileCounts: [String: Int]
    let mode: BackupMode
    let checksum: String
    let compatibilityRange: String
    let userId: String
    let isEncrypted: Bool
    var restoreScope: Set<BackupModule>
    var name: String
    var isStarred: Bool = false

    enum BackupMode: String, Codable {
        case full, incremental, selective
    }
}

enum BackupModule: String, Codable, CaseIterable, Identifiable {
    case workspace, mail, sdk, plugins, connectors, calendar, notes, tasks
    case whiteboards, files, ai, workouts, music, analytics, system_state, ui_state

    var id: String { rawValue }

    var directoryName: String { rawValue }
}

class BackupManager: ObservableObject {
    static let shared = BackupManager()

    private let fileManager = FileManager.default
    private let backupsDirectory: URL
    private let documentsDirectory: URL

    @Published var availableBackups: [BackupMetadata] = []

    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        backupsDirectory = documentsDirectory.appendingPathComponent("Backups")

        try? fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        loadBackups()
    }

    func loadBackups() {
        guard let contents = try? fileManager.contentsOfDirectory(at: backupsDirectory, includingPropertiesForKeys: nil) else { return }

        var loaded: [BackupMetadata] = []
        for file in contents {
            if file.pathExtension == "json" && file.lastPathComponent.contains("_metadata") {
                if let data = try? Data(contentsOf: file),
                   let metadata = try? JSONDecoder().decode(BackupMetadata.self, from: data) {
                    loaded.append(metadata)
                }
            }
        }
        availableBackups = loaded.sorted(by: { $0.timestamp > $1.timestamp })
    }

    func createBackup(modules: Set<BackupModule>, mode: BackupMetadata.BackupMode, name: String? = nil, useBackupExtension: Bool = false) async throws -> BackupMetadata {
        let backupID = UUID()
        let timestamp = Date()
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(backupID.uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        var moduleSizes: [String: Int64] = [:]
        var moduleFileCounts: [String: Int] = [:]

        for module in modules {
            let moduleDir = tempDir.appendingPathComponent(module.directoryName)
            try fileManager.createDirectory(at: moduleDir, withIntermediateDirectories: true)

            let result = try exportModule(module, to: moduleDir)
            moduleSizes[module.rawValue] = result.size
            moduleFileCounts[module.rawValue] = result.fileCount
        }

        let totalRawSize = moduleSizes.values.reduce(0, +)
        let backupName = name ?? generateSmartName(timestamp: timestamp)

        var metadata = BackupMetadata(
            id: backupID,
            timestamp: timestamp,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
            deviceInfo: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            totalSizeCompressed: 0,
            totalSizeRaw: totalRawSize,
            moduleSizes: moduleSizes,
            moduleFileCounts: moduleFileCounts,
            mode: mode,
            checksum: "",
            compatibilityRange: ">=1.0.0",
            userId: "anonymous",
            isEncrypted: false,
            restoreScope: modules,
            name: backupName
        )

        let metadataURL = tempDir.appendingPathComponent("metadata.json")
        try JSONEncoder().encode(metadata).write(to: metadataURL)

        let extensionName = useBackupExtension ? "backup" : "zip"
        let archiveURL = backupsDirectory.appendingPathComponent("\(backupID.uuidString).\(extensionName)")
        try fileManager.zipItem(at: tempDir, to: archiveURL)

        let compressedSize = (try? fileManager.attributesOfItem(atPath: archiveURL.path)[.size] as? Int64) ?? 0

        // Calculate Checksum using streaming to avoid OOM
        let checksum = try SHA256Hash(url: archiveURL)

        let updatedMetadata = BackupMetadata(
            id: metadata.id,
            timestamp: metadata.timestamp,
            appVersion: metadata.appVersion,
            buildNumber: metadata.buildNumber,
            deviceInfo: metadata.deviceInfo,
            osVersion: metadata.osVersion,
            totalSizeCompressed: compressedSize,
            totalSizeRaw: metadata.totalSizeRaw,
            moduleSizes: metadata.moduleSizes,
            moduleFileCounts: metadata.moduleFileCounts,
            mode: metadata.mode,
            checksum: checksum,
            compatibilityRange: metadata.compatibilityRange,
            userId: metadata.userId,
            isEncrypted: metadata.isEncrypted,
            restoreScope: metadata.restoreScope,
            name: metadata.name,
            isStarred: metadata.isStarred
        )

        let finalMetadataURL = backupsDirectory.appendingPathComponent("\(backupID.uuidString)_metadata.json")
        try JSONEncoder().encode(updatedMetadata).write(to: finalMetadataURL)

        try? fileManager.removeItem(at: tempDir)

        await MainActor.run { loadBackups() }
        return updatedMetadata
    }

    private func exportModule(_ module: BackupModule, to destination: URL) throws -> (size: Int64, fileCount: Int) {
        let sourceURL: URL? = {
            switch module {
            case .workspace, .notes, .tasks, .files, .whiteboards, .calendar:
                return documentsDirectory.appendingPathComponent("Workspace")
            case .ai:
                return documentsDirectory.appendingPathComponent("AI")
            case .mail:
                return documentsDirectory.appendingPathComponent("Mail")
            case .music:
                return documentsDirectory.appendingPathComponent("Music")
            case .workouts:
                return documentsDirectory.appendingPathComponent("Workouts")
            case .sdk, .plugins, .connectors:
                return documentsDirectory.appendingPathComponent("Developer")
            case .analytics:
                return documentsDirectory.appendingPathComponent("Analytics")
            default:
                return nil
            }
        }()

        var totalSize: Int64 = 0
        var fileCount = 0

        if let source = sourceURL, fileManager.fileExists(atPath: source.path) {
            let files = try fileManager.subpathsOfDirectory(atPath: source.path)
            for file in files {
                let subSource = source.appendingPathComponent(file)
                let subDest = destination.appendingPathComponent(file)

                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: subSource.path, isDirectory: &isDir) {
                    if isDir.boolValue {
                        try fileManager.createDirectory(at: subDest, withIntermediateDirectories: true)
                    } else {
                        try fileManager.createDirectory(at: subDest.deletingLastPathComponent(), withIntermediateDirectories: true)
                        try fileManager.copyItem(at: subSource, to: subDest)
                        totalSize += (try? fileManager.attributesOfItem(atPath: subSource.path)[.size] as? Int64) ?? 0
                        fileCount += 1
                    }
                }
            }
        }

        // Handle User Defaults / Settings for system_state and ui_state
        if module == .system_state || module == .ui_state {
            let defaultsData = try JSONSerialization.data(withJSONObject: UserDefaults.standard.dictionaryRepresentation(), options: .prettyPrinted)
            let settingsURL = destination.appendingPathComponent("settings.json")
            try defaultsData.write(to: settingsURL)
            totalSize += Int64(defaultsData.count)
            fileCount += 1
        }

        return (totalSize, fileCount)
    }

    func restoreBackup(metadata: BackupMetadata, modules: Set<BackupModule>) async throws {
        let archiveURL = getArchiveURL(for: metadata)
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("Restore_\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try fileManager.unzipItem(at: archiveURL, to: tempDir)

        for module in modules {
            let moduleDir = tempDir.appendingPathComponent(module.directoryName)
            if fileManager.fileExists(atPath: moduleDir.path) {
                try importModule(module, from: moduleDir)
            }
        }

        try? fileManager.removeItem(at: tempDir)
    }

    private func importModule(_ module: BackupModule, from source: URL) throws {
        let targetURL: URL? = {
            switch module {
            case .workspace, .notes, .tasks, .files, .whiteboards, .calendar:
                return documentsDirectory.appendingPathComponent("Workspace")
            case .ai:
                return documentsDirectory.appendingPathComponent("AI")
            case .mail:
                return documentsDirectory.appendingPathComponent("Mail")
            case .music:
                return documentsDirectory.appendingPathComponent("Music")
            case .workouts:
                return documentsDirectory.appendingPathComponent("Workouts")
            case .sdk, .plugins, .connectors:
                return documentsDirectory.appendingPathComponent("Developer")
            case .analytics:
                return documentsDirectory.appendingPathComponent("Analytics")
            default:
                return nil
            }
        }()

        if let target = targetURL {
            try? fileManager.createDirectory(at: target, withIntermediateDirectories: true)
            let files = try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
            for file in files {
                let dest = target.appendingPathComponent(file.lastPathComponent)
                if fileManager.fileExists(atPath: dest.path) {
                    try fileManager.removeItem(at: dest)
                }
                try fileManager.copyItem(at: file, to: dest)
            }
        }

        if module == .system_state || module == .ui_state {
            let settingsURL = source.appendingPathComponent("settings.json")
            if let data = try? Data(contentsOf: settingsURL),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                for (key, value) in dict {
                    UserDefaults.standard.set(value, forKey: key)
                }
            }
        }
    }

    func deleteBackup(metadata: BackupMetadata) {
        let archiveURL = getArchiveURL(for: metadata)
        let metadataURL = backupsDirectory.appendingPathComponent("\(metadata.id.uuidString)_metadata.json")
        try? fileManager.removeItem(at: archiveURL)
        try? fileManager.removeItem(at: metadataURL)
        loadBackups()
    }

    private func generateSmartName(timestamp: Date) -> String {
        let hour = Calendar.current.component(.hour, from: timestamp)
        let prefix = hour < 12 ? "Morning" : (hour < 18 ? "Afternoon" : "Evening")
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return "\(prefix) \(formatter.string(from: timestamp)) Snapshot"
    }

    func getArchiveURL(for metadata: BackupMetadata) -> URL {
        let zipURL = backupsDirectory.appendingPathComponent("\(metadata.id.uuidString).zip")
        let backupURL = backupsDirectory.appendingPathComponent("\(metadata.id.uuidString).backup")

        if fileManager.fileExists(atPath: backupURL.path) {
            return backupURL
        }
        return zipURL
    }

    func importBackupFile(from url: URL) async throws -> BackupMetadata {
        let backupID = UUID()
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("Import_\(backupID.uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Ensure the file is accessible
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "BackupManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied to access file"])
        }
        defer { url.stopAccessingSecurityScopedResource() }

        try fileManager.unzipItem(at: url, to: tempDir)

        let metadataURL = tempDir.appendingPathComponent("metadata.json")
        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(BackupMetadata.self, from: data) else {
            try? fileManager.removeItem(at: tempDir)
            throw NSError(domain: "BackupManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid backup file: Missing or corrupt metadata.json"])
        }

        // Assign new ID to avoid collisions
        let newMetadata = BackupMetadata(
            id: backupID,
            timestamp: metadata.timestamp,
            appVersion: metadata.appVersion,
            buildNumber: metadata.buildNumber,
            deviceInfo: metadata.deviceInfo,
            osVersion: metadata.osVersion,
            totalSizeCompressed: metadata.totalSizeCompressed,
            totalSizeRaw: metadata.totalSizeRaw,
            moduleSizes: metadata.moduleSizes,
            moduleFileCounts: metadata.moduleFileCounts,
            mode: metadata.mode,
            checksum: metadata.checksum,
            compatibilityRange: metadata.compatibilityRange,
            userId: metadata.userId,
            isEncrypted: metadata.isEncrypted,
            restoreScope: metadata.restoreScope,
            name: "Imported: \(metadata.name)"
        )

        let extensionName = url.pathExtension == "backup" ? "backup" : "zip"
        let finalArchiveURL = backupsDirectory.appendingPathComponent("\(backupID.uuidString).\(extensionName)")
        try fileManager.copyItem(at: url, to: finalArchiveURL)

        let finalMetadataURL = backupsDirectory.appendingPathComponent("\(backupID.uuidString)_metadata.json")
        try JSONEncoder().encode(newMetadata).write(to: finalMetadataURL)

        try? fileManager.removeItem(at: tempDir)
        await MainActor.run { loadBackups() }
        return newMetadata
    }

    private func SHA256Hash(url: URL) throws -> String {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }

        var hasher = SHA256()
        let bufferSize = 1024 * 1024 // 1MB
        while true {
            let data = try file.read(upToCount: bufferSize) ?? Data()
            if data.isEmpty { break }
            hasher.update(data: data)
        }

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func toggleStar(for metadata: BackupMetadata) {
        var updated = metadata
        updated.isStarred.toggle()
        let metadataURL = backupsDirectory.appendingPathComponent("\(metadata.id.uuidString)_metadata.json")
        try? JSONEncoder().encode(updated).write(to: metadataURL)
        loadBackups()
    }
}
