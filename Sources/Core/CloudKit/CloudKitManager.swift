import Foundation
import CloudKit
import Combine
import OSLog

public final class CloudKitManager: ObservableObject {
    public static let shared = CloudKitManager()

    private static let containerIdentifier = "iCloud.com.toolskit.app"
    private let container = CKContainer(identifier: CloudKitManager.containerIdentifier)
    private let logger = Logger(subsystem: "com.toolskit.app", category: "CloudKitManager")

    public var privateDatabase: CKDatabase { container.privateCloudDatabase }
    public var publicDatabase: CKDatabase { container.publicCloudDatabase }
    public var sharedDatabase: CKDatabase { container.sharedCloudDatabase }

    @Published public private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

    private init() {
        validateConfiguration()
        Task {
            await checkAccountStatus()
        }
    }

    private func validateConfiguration() {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let expectedSuffix = CloudKitManager.containerIdentifier.replacingOccurrences(of: "iCloud.", with: "")
        if bundleID != expectedSuffix {
            logger.warning("Bundle ID \(bundleID, privacy: .public) does not match CloudKit container suffix \(expectedSuffix, privacy: .public).")
        }
    }

    @discardableResult
    public func checkAccountStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                self.accountStatus = status
            }
            return status == .available
        } catch {
            await MainActor.run {
                self.accountStatus = .couldNotDetermine
            }
            return false
        }
    }

    public func requestPermissionsIfNeeded() {
        Task {
            let isAvailable = await checkAccountStatus()
            guard isAvailable else {
                logger.info("Skipping CloudKit permission request because iCloud account is unavailable.")
                return
            }

            container.requestApplicationPermission(.userDiscoverability) { [logger] status, error in
                if let error {
                    logger.error("CloudKit discoverability permission request failed: \(error.localizedDescription, privacy: .public)")
                    return
                }
                logger.info("CloudKit discoverability permission status: \(status.rawValue)")
            }
        }
    }

    public func isCloudKitAvailable() async -> Bool {
        await checkAccountStatus()
    }

    public func getUserRecordID() async throws -> CKRecord.ID {
        try await container.userRecordID()
    }
}
