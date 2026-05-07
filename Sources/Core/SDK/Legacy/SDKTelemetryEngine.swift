import Foundation

public final class SDKTelemetryEngine: ObservableObject {
    public static let shared = SDKTelemetryEngine()

    @Published public private(set) var activeTraces: [UUID: SDKTrace] = [:]
    @Published public private(set) var completedTraces: [SDKTrace] = []

    private let maxCompletedTraces = 500
    private let persistenceURL: URL
    private let queue = DispatchQueue(label: "com.toolskit.sdk.telemetry", qos: .utility)

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        persistenceURL = appSupport.appendingPathComponent("sdk_telemetry.json")

        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
    }

    public func startTrace(id: UUID, action: SDKAction) {
        let trace = SDKTrace(id: id, action: action, startTime: Date())
        activeTraces[id] = trace
        Task { @MainActor in SDKLogStore.shared.log("Trace started: \(action)", source: "SDKTelemetryEngine", level: LogLevel.debug) }
    }

    public func endTrace(id: UUID, status: TraceStatus) {
        guard var trace = activeTraces[id] else { return }
        trace.endTime = Date()
        trace.status = status
        activeTraces.removeValue(forKey: id)

        completedTraces.insert(trace, at: 0)
        if completedTraces.count > maxCompletedTraces {
            completedTraces = Array(completedTraces.prefix(maxCompletedTraces))
        }

        let duration = trace.endTime!.timeIntervalSince(trace.startTime)
        Task { @MainActor in SDKLogStore.shared.log("Trace ended: \(trace.action) in \(String(format: "%.3f", duration))s [\(status)]", source: "SDKTelemetryEngine", level: LogLevel.info) }

        persistTraces()
    }

    public func getMetrics() -> TelemetryMetrics {
        let total = completedTraces.count
        let successes = completedTraces.filter {
            if case .success = $0.status { return true }
            return false
        }.count
        let avgDuration = completedTraces.compactMap { trace -> TimeInterval? in
            guard let end = trace.endTime else { return nil }
            return end.timeIntervalSince(trace.startTime)
        }
        let avgMs = avgDuration.isEmpty ? 0 : avgDuration.reduce(0, +) / Double(avgDuration.count) * 1000

        return TelemetryMetrics(
            totalTraces: total,
            successCount: successes,
            failureCount: total - successes,
            averageDurationMs: avgMs,
            activeTraces: activeTraces.count
        )
    }

    private func persistTraces() {
        let tracesSnapshot = completedTraces
        queue.async { [weak self] in
            guard let self = self else { return }

            struct TraceRecord: Codable {
                let id: UUID
                let actionDescription: String
                let startTime: Date
                let endTime: Date
                let success: Bool
            }

            let records = tracesSnapshot.prefix(100).compactMap { trace -> TraceRecord? in
                guard let endTime = trace.endTime else { return nil }
                let success: Bool
                if case .success = trace.status { success = true } else { success = false }
                return TraceRecord(id: trace.id, actionDescription: "\(trace.action)", startTime: trace.startTime, endTime: endTime, success: success)
            }

            if let data = try? JSONEncoder().encode(records) {
                try? data.write(to: self.persistenceURL)
            }
        }
    }
}

public struct SDKTrace {
    public let id: UUID
    public let action: SDKAction
    public let startTime: Date
    public var endTime: Date?
    public var status: TraceStatus = .pending
}

public enum TraceStatus {
    case pending
    case success
    case failure(Error)
}

public struct TelemetryMetrics {
    public let totalTraces: Int
    public let successCount: Int
    public let failureCount: Int
    public let averageDurationMs: Double
    public let activeTraces: Int
}
