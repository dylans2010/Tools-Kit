import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "com.toolskit.openclaw", category: "diagnostics")

struct OpenClawMetric: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let timestamp: Date
}

enum OpenClawDiagnosticType: String {
    case info = "INFO"
    case error = "ERROR"
    case network = "NETWORK"
    case protocolMsg = "PROTOCOL"
}

@Observable
final class OpenClawDiagnosticsManager {
    static let shared = OpenClawDiagnosticsManager()

    var metrics: [OpenClawMetric] = []
    var logs: [String] = []

    @MainActor
    func log(_ message: String, type: OpenClawDiagnosticType = .info) {
        #if DEBUG
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let formatted = "[\(timestamp)] [\(type.rawValue)] \(message)"
        self.logs.append(formatted)
        if self.logs.count > 1000 { self.logs.removeFirst() }

        switch type {
        case .info: logger.info("\(message)")
        case .error: logger.error("\(message)")
        case .network: logger.debug("[NETWORK] \(message)")
        case .protocolMsg: logger.debug("[PROTOCOL] \(message)")
        }
        #endif
    }

    @MainActor
    func recordMetric(name: String, value: String) {
        self.metrics.append(OpenClawMetric(name: name, value: value, timestamp: Date()))
        if self.metrics.count > 100 { self.metrics.removeFirst() }
    }
}
