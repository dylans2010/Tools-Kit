import Foundation

enum LogViewerLevel: String, CaseIterable, Identifiable {
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

struct LogViewerEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogViewerLevel
    let message: String
}

class LogViewerBackend: ObservableObject {
    @Published var entries: [LogViewerEntry] = []
    @Published var selectedFilter: LogViewerLevel? = nil

    func addLog(_ message: String, level: LogViewerLevel = .info) {
        let entry = LogViewerEntry(timestamp: Date(), level: level, message: message)
        entries.append(entry)
    }

    func clearLogs() {
        entries = []
    }

    var filteredEntries: [LogViewerEntry] {
        if let filter = selectedFilter {
            return entries.filter { $0.level == filter }
        }
        return entries
    }
}
