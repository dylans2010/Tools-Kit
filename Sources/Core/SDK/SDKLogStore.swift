import Foundation

public enum LogLevel: String, Codable, CaseIterable {
    case debug, info, warning, error
}

public struct SDKLogEntry: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let source: String
    public let message: String
    public let level: LogLevel

    public init(id: UUID = UUID(), timestamp: Date = Date(), source: String, message: String, level: LogLevel) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.message = message
        self.level = level
    }
}

@MainActor
public final class SDKLogStore: ObservableObject {
    public static let shared = SDKLogStore()

    @Published public var entries: [SDKLogEntry] = []

    private let saveURL: URL
    private let queue = DispatchQueue(label: "com.toolskit.sdk.logstore", qos: .background)

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        saveURL = appSupport.appendingPathComponent("sdk_logs.json")

        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        loadFromDisk()
    }

    public func log(_ message: String, source: String, level: LogLevel) {
        let entry = SDKLogEntry(source: source, message: message, level: level)
        entries.insert(entry, at: 0)

        if entries.count > 1000 {
            entries = Array(entries.prefix(1000))
        }

        saveToDisk()
    }

    public func entries(for source: String) -> [SDKLogEntry] {
        return entries.filter { $0.source == source }
    }

    public func clear() {
        entries.removeAll()
        saveToDisk()
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([SDKLogEntry].self, from: data) else {
            return
        }
        self.entries = decoded
    }

    private func saveToDisk() {
        let currentEntries = entries
        queue.async {
            if let data = try? JSONEncoder().encode(currentEntries) {
                try? data.write(to: self.saveURL)
            }
        }
    }
}
