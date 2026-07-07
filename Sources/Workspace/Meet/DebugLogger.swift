import Foundation
import Combine
#if canImport(Daily)
import Daily
#endif

enum DebugLogLevel: String, Codable {
    case info
    case warning
    case error
    case debug
}

struct DebugLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: DebugLogLevel
    let category: String
    let message: String
}

@MainActor
final class DebugLogger: ObservableObject {
    static let shared = DebugLogger()

    @Published private(set) var entries: [DebugLogEntry] = []
    private let maxEntries = 800

    private init() {}

    func log(_ message: String, level: DebugLogLevel = .info, category: String = "Meet") {
        let entry = DebugLogEntry(
            id: UUID(),
            timestamp: Date(),
            level: level,
            category: category,
            message: message
        )
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
    }

    func clear() {
        entries.removeAll()
    }
}
