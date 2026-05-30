import Foundation

public class AnalyticsService: ObservableObject {
    public static let shared = AnalyticsService()
    private let store = DeveloperPersistentStore.shared

    private init() {}

    public func fetchInstallTrend(appID: UUID?, from: Date, to: Date) async throws -> [InstallEvent] {
        return store.installEvents.filter { event in
            (appID == nil || event.appID == appID) &&
            event.timestamp >= from &&
            event.timestamp <= to
        }
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
        let events = store.customEventDefinitions
        var counts: [Int] = []

        for step in funnel.steps {
            let count = events.filter { $0.eventName == step.eventName }.count
            counts.append(count)
        }

        guard let firstCount = counts.first, firstCount > 0 else {
            return Array(repeating: 0.0, count: funnel.steps.count)
        }

        return counts.map { Double($0) / Double(firstCount) }
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
