import Foundation

/// Low-level database engine for the WorkspaceSDK.
/// Handles atomic file I/O, directory management, and raw data access.
public final class SDKDatabase {
    public static let shared = SDKDatabase()

    private let baseURL: URL
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.toolskit.sdk.database", qos: .userInitiated, attributes: .concurrent)

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        baseURL = appSupport.appendingPathComponent("WorkspaceSDK/Database", isDirectory: true)
        setupDirectory()
    }

    private func setupDirectory() {
        if !fileManager.fileExists(atPath: baseURL.path) {
            try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
    }

    // MARK: - I/O Operations

    public func write(data: Data, to path: String) throws {
        let url = baseURL.appendingPathComponent(path)
        try queue.sync(flags: .barrier) {
            try data.write(to: url, options: .atomic)
        }
    }

    public func read(from path: String) throws -> Data {
        let url = baseURL.appendingPathComponent(path)
        return try queue.sync {
            guard fileManager.fileExists(atPath: url.path) else {
                throw SDKError.storageError(reason: "File not found at \(path)")
            }
            return try Data(contentsOf: url)
        }
    }

    public func delete(path: String) throws {
        let url = baseURL.appendingPathComponent(path)
        try queue.sync(flags: .barrier) {
            if self.fileManager.fileExists(atPath: url.path) {
                try self.fileManager.removeItem(at: url)
            }
        }
    }

    public func exists(path: String) -> Bool {
        let url = baseURL.appendingPathComponent(path)
        return queue.sync {
            fileManager.fileExists(atPath: url.path)
        }
    }

    public func listFiles(in directory: String = "") -> [String] {
        let url = directory.isEmpty ? baseURL : baseURL.appendingPathComponent(directory)
        return queue.sync {
            (try? fileManager.contentsOfDirectory(atPath: url.path)) ?? []
        }
    }
}
