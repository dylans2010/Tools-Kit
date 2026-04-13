import Foundation

/// Lightweight shared logger that integrates with LogViewerBackend.
final class InternalLogger: ObservableObject {
    static let shared = InternalLogger()

    @Published private(set) var entries: [InternalLogEntry] = []

    private init() {}

    func log(_ message: String, level: LogViewerLevel = .info) {
        let entry = InternalLogEntry(
            timestamp: Date(),
            level: level,
            message: message
        )
        DispatchQueue.main.async {
            self.entries.append(entry)
            if self.entries.count > 500 { self.entries.removeFirst() }
        }
        let prefix: String
        switch level {
        case .info:    prefix = "ℹ️"
        case .warning: prefix = "⚠️"
        case .error:   prefix = "❌"
        case .debug:   prefix = "🐛"
        }
        print("\(prefix) [\(level.rawValue.uppercased())] \(message)")
    }

    func clear() {
        entries.removeAll()
    }
}

struct InternalLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogViewerLevel
    let message: String
}
