import Foundation
import Combine

public enum LogLevel: String, Codable, CaseIterable, Hashable {
    case debug
    case info
    case warning
    case error
}

public struct SDKLogEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let source: String?
    public init(id: UUID = UUID(), timestamp: Date = Date(),
                level: LogLevel, message: String, source: String? = nil) {
        self.id = id; self.timestamp = timestamp
        self.level = level; self.message = message; self.source = source
    }
}

public class SDKLogStore: ObservableObject {
    public static let shared = SDKLogStore()
    @Published public var entries: [SDKLogEntry] = []
    private init() {}
    public func log(_ message: String, level: LogLevel = .info,
                    source: String? = nil) {
        let entry = SDKLogEntry(level: level, message: message, source: source)
        DispatchQueue.main.async { self.entries.append(entry) }
    }
}
