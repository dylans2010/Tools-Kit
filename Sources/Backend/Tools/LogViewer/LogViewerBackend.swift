import Foundation

enum LogLevel: String, CaseIterable, Identifiable {
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
    case debug = "Debug"

    var id: String { self.rawValue }

    var symbol: String {
        switch self {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .debug: return "🐛"
        }
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
}

class LogViewerBackend: ObservableObject {
    @Published var entries: [LogEntry] = []
    @Published var selectedFilter: LogLevel? = nil

    func addLog(_ message: String, level: LogLevel = .info) {
        let entry = LogEntry(timestamp: Date(), level: level, message: message)
        entries.append(entry)
    }

    func clearLogs() {
        entries = []
    }

    var filteredEntries: [LogEntry] {
        if let filter = selectedFilter {
            return entries.filter { $0.level == filter }
        }
        return entries
    }
}
