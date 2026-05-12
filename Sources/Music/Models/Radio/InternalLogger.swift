import Foundation

/// Lightweight shared logger that integrates with LogViewerBackend levels for cross-module error reporting.
final class InternalLogger {
    static let shared = InternalLogger()

    private var entries: [InternalLogEntry] = []
    private let maxEntries = 500

    private init() {}

    func log(_ message: String, level: LogViewerLevel = .info) {
        let entry = InternalLogEntry(timestamp: Date(), level: level, message: message)
        if Thread.isMainThread {
            appendEntry(entry)
        } else {
            DispatchQueue.main.async { self.appendEntry(entry) }
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

    private func appendEntry(_ entry: InternalLogEntry) {
        entries.append(entry)
        if entries.count > maxEntries { entries.removeFirst() }
    }
}

struct InternalLogEntry: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let level: LogViewerLevel
    let message: String
}
