import Foundation
import Combine

/// Protocol for the SDK data persistence layer.
public protocol SDKDataStoreProtocol {
    func save<T: SDKModel>(_ model: T) throws
    func fetch<T: SDKModel>(_ type: T.Type, id: UUID) -> T?
    func fetchAll<T: SDKModel>(_ type: T.Type) -> [T]
    func delete<T: SDKModel>(_ type: T.Type, id: UUID) throws
    func query<T: SDKModel>(_ type: T.Type, predicate: (T) -> Bool) -> [T]
}

/// Unified offline-first data persistence layer for the SDK.
/// Supports file-based JSON storage with indexing and versioning.
public final class SDKDataStore: SDKDataStoreProtocol, ObservableObject {
    public static let shared = SDKDataStore()

    @Published public private(set) var isInitialized = false
    @Published public private(set) var totalRecords = 0

    private let baseURL: URL
    private var collections: [String: [UUID: Data]] = [:]
    private var indices: [String: [String: Set<UUID>]] = [:]
    private let queue = DispatchQueue(label: "com.toolskit.sdk.datastore", qos: .utility)
    private let schemaVersion = 2

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        baseURL = appSupport.appendingPathComponent("WorkspaceSDK/DataStore")
    }

    public func initialize() {
        queue.sync {
            if !FileManager.default.fileExists(atPath: baseURL.path) {
                try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
            }
            loadAllCollections()
            isInitialized = true
        }
    }

    // MARK: - CRUD

    public func save<T: SDKModel>(_ model: T) throws {
        let collectionName = String(describing: T.self)
        let data = try JSONEncoder().encode(model)

        queue.sync {
            if collections[collectionName] == nil {
                collections[collectionName] = [:]
            }
            collections[collectionName]?[model.id] = data
            updateIndices(for: collectionName, id: model.id, model: model)
            totalRecords = collections.values.reduce(0) { $0 + $1.count }
        }

        persistCollection(collectionName)
    }

    public func fetch<T: SDKModel>(_ type: T.Type, id: UUID) -> T? {
        let collectionName = String(describing: T.self)
        guard let data = queue.sync(execute: { collections[collectionName]?[id] }) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    public func fetchAll<T: SDKModel>(_ type: T.Type) -> [T] {
        let collectionName = String(describing: T.self)
        let allData = queue.sync { collections[collectionName]?.values ?? [:].values }
        return allData.compactMap { try? JSONDecoder().decode(T.self, from: $0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func delete<T: SDKModel>(_ type: T.Type, id: UUID) throws {
        let collectionName = String(describing: T.self)
        queue.sync {
            collections[collectionName]?.removeValue(forKey: id)
            removeFromIndices(collectionName: collectionName, id: id)
            totalRecords = collections.values.reduce(0) { $0 + $1.count }
        }
        persistCollection(collectionName)
    }

    public func query<T: SDKModel>(_ type: T.Type, predicate: (T) -> Bool) -> [T] {
        return fetchAll(type).filter(predicate)
    }

    // MARK: - Batch Operations

    public func batchSave<T: SDKModel>(_ models: [T]) throws {
        for model in models {
            try save(model)
        }
    }

    public func deleteAll<T: SDKModel>(_ type: T.Type) {
        let collectionName = String(describing: T.self)
        queue.sync {
            collections[collectionName]?.removeAll()
            indices[collectionName]?.removeAll()
            totalRecords = collections.values.reduce(0) { $0 + $1.count }
        }
        persistCollection(collectionName)
    }

    // MARK: - Index Queries

    public func fetchByIndex<T: SDKModel>(_ type: T.Type, indexKey: String, value: String) -> [T] {
        let collectionName = String(describing: T.self)
        guard let ids = queue.sync(execute: { indices[collectionName]?["\(indexKey):\(value)"] }) else { return [] }
        return ids.compactMap { fetch(type, id: $0) }
    }

    // MARK: - Flush

    public func flush() {
        queue.sync {
            for collectionName in collections.keys {
                persistCollectionSync(collectionName)
            }
        }
    }

    // MARK: - Stats

    public func collectionStats() -> [String: Int] {
        return queue.sync {
            collections.mapValues { $0.count }
        }
    }

    // MARK: - Private

    private func updateIndices<T: SDKModel>(for collection: String, id: UUID, model: T) {
        if indices[collection] == nil {
            indices[collection] = [:]
        }
        let typeKey = "type:\(String(describing: T.self))"
        if indices[collection]?[typeKey] == nil {
            indices[collection]?[typeKey] = []
        }
        indices[collection]?[typeKey]?.insert(id)
    }

    private func removeFromIndices(collectionName: String, id: UUID) {
        guard var collectionIndices = indices[collectionName] else { return }
        for key in collectionIndices.keys {
            collectionIndices[key]?.remove(id)
        }
        indices[collectionName] = collectionIndices
    }

    private func persistCollection(_ name: String) {
        queue.async { [weak self] in
            self?.persistCollectionSync(name)
        }
    }

    private func persistCollectionSync(_ name: String) {
        guard let items = collections[name] else { return }
        let url = baseURL.appendingPathComponent("\(name).json")
        let storableItems = items.mapKeys { $0.uuidString }
        if let data = try? JSONEncoder().encode(storableItems) {
            try? data.write(to: url)
        }
    }

    private func loadAllCollections() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension == "json" {
            let name = file.deletingPathExtension().lastPathComponent
            if let data = try? Data(contentsOf: file),
               let decoded = try? JSONDecoder().decode([String: Data].self, from: data) {
                collections[name] = decoded.reduce(into: [:]) { result, pair in
                    if let uuid = UUID(uuidString: pair.key) {
                        result[uuid] = pair.value
                    }
                }
            }
        }
        totalRecords = collections.values.reduce(0) { $0 + $1.count }
    }
}

// MARK: - Dictionary Helper

private extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }
}
