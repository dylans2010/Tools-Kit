import Foundation
import Combine
import SwiftUI

public final class LocalFileConnector: BaseConnector {
    public let id = UUID()
    public let name = "Local Files"
    public let type: ConnectorType = .localFileSystem
    @Published public var status: ConnectorStatus = .connected

    public var authFields: [AuthField] { [] }

    @Published public var activityLog: [ConnectorEvent] = []
    private var scannedFileCount = 0

    public init() {}

    public func authenticate(credentials: [String: String]) async throws {
        status = .connected
        log("Local file system connected", level: .info)
    }

    public func sync() async throws {
        log("Scanning sandbox documents...", level: .info)

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let documentsURL = documentsURL else {
            log("Documents directory not accessible", level: .error)
            throw SDKError.executionFailed(reason: "Documents directory not accessible")
        }

        let fileManager = FileManager.default
        var fileCount = 0
        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: documentsURL, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]) {
            while let url = enumerator.nextObject() as? URL {
                let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                if resourceValues?.isRegularFile == true {
                    fileCount += 1
                    totalSize += Int64(resourceValues?.fileSize ?? 0)
                }
            }
        }

        scannedFileCount = fileCount
        let sizeString = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        log("Scanned \(fileCount) files (\(sizeString))", level: .info)
    }

    public func testConnection() async throws -> Bool {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsURL != nil && FileManager.default.fileExists(atPath: documentsURL!.path)
    }

    public func disconnect() {
        status = .disconnected
        log("Local files disconnected", level: .info)
    }

    private func log(_ message: String, level: LogLevel) {
        let event = ConnectorEvent(id: UUID(), timestamp: Date(), message: message, level: level)
        activityLog.insert(event, at: 0)
        Task { @MainActor in
            SDKLogStore.shared.log(message, source: "LocalFileConnector", level: level)
        }
    }
}
