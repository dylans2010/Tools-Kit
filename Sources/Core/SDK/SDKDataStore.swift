import Foundation

/// Protocol for all models stored in the WorkspaceSDK.
public protocol SDKModel: Identifiable, Codable {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

/// Unified Data Store for the WorkspaceSDK.
/// Provides offline-first persistence and querying for all SDK modules.
public final class SDKDataStore {
    public static let shared = SDKDataStore()

    private let storageURL: URL
    private let queue = DispatchQueue(label: "com.toolskit.sdk.datastore", attributes: .concurrent)

    private init() {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        self.storageURL = paths[0].appendingPathComponent("WorkspaceSDK/Data")
        try? FileManager.default.createDirectory(at: self.storageURL, withIntermediateDirectories: true)
    }

    public func save<T: SDKModel>(_ model: T, in collection: String) throws {
        try queue.sync(flags: .barrier) {
            let collectionURL = storageURL.appendingPathComponent(collection)
            try? FileManager.default.createDirectory(at: collectionURL, withIntermediateDirectories: true)

            let fileURL = collectionURL.appendingPathComponent("\(model.id.uuidString).json")
            let data = try JSONEncoder().encode(model)
            try data.write(to: fileURL)
        }
    }

    public func fetch<T: SDKModel>(id: UUID, in collection: String) throws -> T? {
        return try queue.sync {
            let fileURL = storageURL.appendingPathComponent(collection).appendingPathComponent("\(id.uuidString).json")
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(T.self, from: data)
        }
    }

    public func fetchAll<T: SDKModel>(in collection: String) throws -> [T] {
        return try queue.sync {
            let collectionURL = storageURL.appendingPathComponent(collection)
            guard FileManager.default.fileExists(atPath: collectionURL.path) else { return [] }

            let files = try FileManager.default.contentsOfDirectory(at: collectionURL, includingPropertiesForKeys: nil)
            return try files.compactMap { fileURL in
                let data = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode(T.self, from: data)
            }
        }
    }

    public func delete(id: UUID, in collection: String) throws {
        try queue.sync(flags: .barrier) {
            let fileURL = storageURL.appendingPathComponent(collection).appendingPathComponent("\(id.uuidString).json")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    }
}

// MARK: - Service Registration logic would go in ServiceContainer later
