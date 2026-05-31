import Foundation

public class AnalyticsService: ObservableObject {
    public static let shared = AnalyticsService()
    private let store = DeveloperPersistentStore.shared

    private init() {}

    public var customEvents: [CustomEventRecord] {
        store.customEvents
    }

    public var funnels: [AnalyticsFunnel] {
        store.funnels
    }

    public func fetchInstallTrend(appID: UUID?, from: Date, to: Date) async throws -> [InstallEvent] {
        return []
    }

    public func fetchAPIUsage(appID: UUID?, from: Date, to: Date) async throws -> [LogEntry] {
        let logs = store.logEntries
        return logs.filter { log in
            log.category == .apiCall &&
            log.timestamp >= from &&
            log.timestamp <= to
        }
    }

    public func fetchErrorSummary(appID: UUID?, from: Date, to: Date) async throws -> [String: Int] {
        let logs = store.logEntries
        let errorLogs = logs.filter { log in
            (log.severity == .error || log.severity == .critical) &&
            log.timestamp >= from &&
            log.timestamp <= to
        }

        var summary: [String: Int] = [:]
        for log in errorLogs {
            summary[log.message, default: 0] += 1
        }
        return summary
    }

    public func computeFunnel(funnel: AnalyticsFunnel) async throws -> [Double] {
        return Array(repeating: 0.0, count: funnel.steps.count)
    }

    public func exportMetrics(appID: UUID?, from: Date, to: Date, format: String) async throws -> URL {
        let apiUsage = try await fetchAPIUsage(appID: appID, from: from, to: to)
        let errors = try await fetchErrorSummary(appID: appID, from: from, to: to)

        let exportData = [
            "api_usage_count": apiUsage.count,
            "error_summary": errors
        ] as [String : Any]

        let data = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("analytics_export_\(Date().timeIntervalSince1970).\(format)")
        try data.write(to: fileURL)
        return fileURL
    }
}
