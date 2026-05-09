import Foundation
import Combine
import CloudKit

@MainActor
public final class CloudKitSettingsViewModel: ObservableObject {
    @Published public var isCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCloudSyncEnabled, forKey: "CloudKitSyncEnabled")
            if isCloudSyncEnabled {
                startSync()
            }
        }
    }

    @Published public var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published public var isSyncing = false
    @Published public var lastSyncTime: String = "Never"

    private let manager = CloudKitManager.shared
    private let syncEngine = CloudKitSyncEngine.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        self.isCloudSyncEnabled = UserDefaults.standard.bool(forKey: "CloudKitSyncEnabled")

        manager.$accountStatus
            .receive(on: RunLoop.main)
            .assign(to: &$accountStatus)

        syncEngine.$isSyncing
            .receive(on: RunLoop.main)
            .assign(to: &$isSyncing)

        syncEngine.$lastSyncDate
            .receive(on: RunLoop.main)
            .map { date -> String in
                guard let date = date else { return "Never" }
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                return formatter.localizedString(for: date, relativeTo: Date())
            }
            .assign(to: &$lastSyncTime)
    }

    public func toggleCloudSync() {
        isCloudSyncEnabled.toggle()
    }

    public func forceSync() {
        Task {
            await manager.checkAccountStatus()
            if accountStatus == .available {
                await syncEngine.sync()
            }
        }
    }

    public func resetCloudData() {
        Task {
            try? await syncEngine.resetCloudData()
        }
    }

    private func startSync() {
        forceSync()
    }
}
