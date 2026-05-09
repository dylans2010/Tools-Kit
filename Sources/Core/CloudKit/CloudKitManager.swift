import Foundation
import CloudKit
import Combine

public final class CloudKitManager: ObservableObject {
    public static let shared = CloudKitManager()

    private let container = CKContainer(identifier: "iCloud.com.toolskit.app")

    public var privateDatabase: CKDatabase { container.privateCloudDatabase }
    public var publicDatabase: CKDatabase { container.publicCloudDatabase }
    public var sharedDatabase: CKDatabase { container.sharedCloudDatabase }

    @Published public private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

    private init() {
        Task {
            await checkAccountStatus()
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
        container.requestApplicationPermission(.userDiscoverability) { _, _ in }
    }

    public func getUserRecordID() async throws -> CKRecord.ID {
        try await container.userRecordID()
    }
}
