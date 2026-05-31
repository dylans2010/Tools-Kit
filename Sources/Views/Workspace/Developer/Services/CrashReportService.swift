import Foundation

public class CrashReportService: ObservableObject {
    public static let shared = CrashReportService()
    private let store = DeveloperPersistentStore.shared

    @Published public var crashLogs: [CrashLog] = []

    private init() { loadCrashLogs() }

    public func loadCrashLogs() { self.crashLogs = store.crashLogs }

    public func fetchReports(appID: UUID?) async throws -> [CrashLog] {
        if let appID = appID {
            return store.crashLogs.filter { $0.appID == appID }
        }
        return store.crashLogs
    }

    public func reportCrash(_ log: CrashLog) async throws {
        var current = store.crashLogs
        current.insert(log, at: 0)
        store.saveCrashLogs(current)
        let updatedCrashLogs = current
        await MainActor.run { self.crashLogs = updatedCrashLogs }
    }
}
