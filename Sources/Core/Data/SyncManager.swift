import Foundation

class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var lastSync: Date?
    @Published var isSyncing = false

    private init() {}

    func sync() async {
        isSyncing = true
        defer { isSyncing = false }

        // Simulate sync
        try? await Task.sleep(nanoseconds: 500_000_000)
        lastSync = Date()
    }
}
