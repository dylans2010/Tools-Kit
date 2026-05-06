import Foundation

/// Tracks SDK execution performance and logs full execution traces.
public final class SDKTelemetryEngine: ObservableObject {
    public static let shared = SDKTelemetryEngine()

    @Published public private(set) var activeTraces: [UUID: SDKTrace] = [:]

    private init() {}

    public func startTrace(id: UUID, action: SDKAction) {
        let trace = SDKTrace(id: id, action: action, startTime: Date())
        activeTraces[id] = trace
    }

    public func endTrace(id: UUID, status: TraceStatus) {
        guard var trace = activeTraces[id] else { return }
        trace.endTime = Date()
        trace.status = status
        activeTraces[id] = trace

        // In a real app, this might be sent to a backend or persisted locally
        let duration = trace.endTime!.timeIntervalSince(trace.startTime)
        SDKConsoleView.LogBus.shared.log("Trace ended: \(trace.action) in \(String(format: "%.3f", duration))s [\(status)]", type: .info)
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
