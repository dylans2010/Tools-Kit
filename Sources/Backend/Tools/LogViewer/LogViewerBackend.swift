import Foundation

class LogViewerBackend: ObservableObject {
    @Published var logs: [String] = []

    func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let timestamp = formatter.string(from: Date())
        logs.append("[\(timestamp)] \(message)")
    }

    func clearLogs() {
        logs = []
    }
}
