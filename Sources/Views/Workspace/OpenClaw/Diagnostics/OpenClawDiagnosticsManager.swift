import Foundation
import Combine

struct OpenClawMetric: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let timestamp: Date
}

final class OpenClawDiagnosticsManager: ObservableObject {
    static let shared = OpenClawDiagnosticsManager()

    @Published var metrics: [OpenClawMetric] = []
    @Published var logs: [String] = []

    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let formatted = "[\(timestamp)] \(message)"
        DispatchQueue.main.async {
            self.logs.append(formatted)
            if self.logs.count > 1000 { self.logs.removeFirst() }
        }
        print(formatted)
    }

    func recordMetric(name: String, value: String) {
        DispatchQueue.main.async {
            self.metrics.append(OpenClawMetric(name: name, value: value, timestamp: Date()))
            if self.metrics.count > 100 { self.metrics.removeFirst() }
        }
    }
}
