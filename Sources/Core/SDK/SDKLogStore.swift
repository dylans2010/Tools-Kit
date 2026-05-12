import Foundation
import Combine

public struct SDKLogEntry: Identifiable, Codable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var source: String
    public var message: String
    public var level: LogLevel
}

public enum LogLevel: String, Codable, CaseIterable, Sendable {
    case debug, info, warning, error
}

@MainActor
public final class SDKLogStore: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKLogStore()

    @Published public var entries: [SDKLogEntry] = []

    private let logFileURL: URL
    private let maxEntries = 1000
    private let queue = DispatchQueue(label: "com.toolskit.sdk.logstore", qos: .background)

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        logFileURL = appSupport.appendingPathComponent("sdk_logs.json")

        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        loadFromDisk()
    }

    public func log(_ message: String, source: String, level: LogLevel) {
        let entry = SDKLogEntry(id: UUID(), timestamp: Date(), source: source, message: message, level: level)
        entries.insert(entry, at: 0)

        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
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
        guard let data = try? Data(contentsOf: logFileURL) else { return }
        if let decoded = try? JSONDecoder().decode([SDKLogEntry].self, from: data) {
            entries = decoded
        }
    }

    private func saveToDisk() {
        let entriesToSave = entries
        queue.async {
            if let data = try? JSONEncoder().encode(entriesToSave) {
                try? data.write(to: self.logFileURL)
            }
        }
    }
}
