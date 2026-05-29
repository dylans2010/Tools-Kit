import Foundation

public class DeveloperLogService: ObservableObject {
    public static let shared = DeveloperLogService()
    private let store = DeveloperPersistentStore.shared

    @Published public var logEntries: [LogEntry] = []
    @Published public var alertRules: [LogAlertRule] = []
    @Published public var logDrains: [LogDrain] = []

    private init() {
        loadLogEntries()
        loadAlertRules()
        loadLogDrains()
    }

    public func loadLogEntries() {
        self.logEntries = store.logEntries
    }

    public func loadAlertRules() {
        // We could add alertRules to the store if needed, let's use a separate key or extend store
        // For now using the store for logEntries and providing a way to persist others if required.
        // Assuming we extended store in step 1 if needed.
        // self.alertRules = store.load([LogAlertRule].self, key: "alert_rules") ?? []
    }

    public func loadLogDrains() {
        // self.logDrains = store.load([LogDrain].self, key: "log_drains") ?? []
    }

    public func writeLog(severity: LogSeverity, category: LogCategory, message: String, payload: String = "", appID: UUID? = nil) async {
        let entry = LogEntry(
            severity: severity,
            category: category,
            source: LogSource(component: "DeveloperPortal", environment: "Production", version: "1.0.0"),
            message: message,
            payload: payload,
            correlationID: UUID().uuidString
        )

        var currentLogs = store.logEntries
        currentLogs.insert(entry, at: 0)

        // Keep logs to a reasonable limit
        if currentLogs.count > 1000 {
            currentLogs.removeLast()
        }

        store.saveLogs(currentLogs)

        let updatedLogEntries = currentLogs
        await MainActor.run {
            self.logEntries = updatedLogEntries
        }
    }

    public func queryLogs(filters: [String: Any], page: Int = 0) async throws -> [LogEntry] {
        var results = store.logEntries

        if let severity = filters["severity"] as? LogSeverity {
            results = results.filter { $0.severity == severity }
        }

        if let category = filters["category"] as? LogCategory {
            results = results.filter { $0.category == category }
        }

        if let appID = filters["appID"] as? UUID {
            // Assuming we added appID to LogSource or LogEntry
            // results = results.filter { $0.appID == appID }
        }

        let pageSize = 50
        let start = page * pageSize
        let end = min(start + pageSize, results.count)

        guard start < results.count else { return [] }

        return Array(results[start..<end])
    }

    public func searchLogs(query: String, filters: [String: Any]) async throws -> [LogEntry] {
        var results = try await queryLogs(filters: filters)

        if !query.isEmpty {
            results = results.filter {
                $0.message.localizedCaseInsensitiveContains(query) ||
                $0.payload.localizedCaseInsensitiveContains(query)
            }
        }

        return results
    }

    public func exportLogs(format: String, filters: [String: Any]) async throws -> URL {
        let entries = try await queryLogs(filters: filters)
        let data: Data

        if format == "json" {
            data = try JSONEncoder().encode(entries)
        } else {
            // Simple CSV
            var csv = "Timestamp,Severity,Category,Message\n"
            for entry in entries {
                csv += "\(entry.timestamp),\(entry.severity.rawValue),\(entry.category.rawValue),\"\(entry.message)\"\n"
            }
            data = csv.data(using: .utf8) ?? Data()
        }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("logs_export_\(Date().timeIntervalSince1970).\(format)")
        try data.write(to: fileURL)
        return fileURL
    }

    public func saveAlertRule(_ rule: LogAlertRule) async throws {
        if let index = alertRules.firstIndex(where: { $0.id == rule.id }) {
            alertRules[index] = rule
        } else {
            alertRules.append(rule)
        }
        // Persist
    }

    public func deleteAlertRule(id: UUID) async throws {
        alertRules.removeAll { $0.id == id }
        // Persist
    }

    public func saveLogDrain(_ drain: LogDrain) async throws {
        if let index = logDrains.firstIndex(where: { $0.id == drain.id }) {
            logDrains[index] = drain
        } else {
            logDrains.append(drain)
        }
        // Persist
    }

    public func deleteLogDrain(id: UUID) async throws {
        logDrains.removeAll { $0.id == id }
        // Persist
    }
}
