import Foundation
import Combine

/// Unified offline-first data persistence layer for the SDK.
/// Uses SDKDatabase for low-level I/O.
public final class SDKDataStore: SDKDataStoreProtocol, ObservableObject {
    public static let shared = SDKDataStore()

    @Published public private(set) var isInitialized = false
    @Published public private(set) var totalRecords = 0

    private let db = SDKDatabase.shared
    private var collections: [String: [UUID: Data]] = [:]
    private let queue = DispatchQueue(label: "com.toolskit.sdk.datastore", qos: .utility)

    private init() {}

    public func initialize() {
        queue.sync {
            loadAllCollections()
            isInitialized = true
        }
    }

    public func save<T: SDKModel>(_ model: T) throws {
        let collectionName = String(describing: T.self)
        let data = try JSONEncoder().encode(model)

        queue.sync {
            if collections[collectionName] == nil {
                collections[collectionName] = [:]
            }
            collections[collectionName]?[model.id] = data
            totalRecords = collections.values.reduce(0) { $0 + $1.count }
        }

        try persistCollection(collectionName)
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
            totalRecords = collections.values.reduce(0) { $0 + $1.count }
        }
        try persistCollection(collectionName)
    }

    public func query<T: SDKModel>(_ type: T.Type, predicate: (T) -> Bool) -> [T] {
        return fetchAll(type).filter(predicate)
    }

    public func flush() {
        queue.sync {
            for collectionName in collections.keys {
                try? persistCollectionSync(collectionName)
            }
        }
    }

    public func collectionStats() -> [String: Int] {
        return queue.sync {
            collections.mapValues { $0.count }
        }
    }

    private func persistCollection(_ name: String) throws {
        try persistCollectionSync(name)
    }

    private func persistCollectionSync(_ name: String) throws {
        guard let items = collections[name] else { return }
        let storableItems = items.reduce(into: [String: Data]()) { $0[$1.key.uuidString] = $1.value }
        let data = try JSONEncoder().encode(storableItems)
        try db.write(data: data, to: "\(name).json")
    }

    private func loadAllCollections() {
        let files = db.listFiles().filter { $0.hasSuffix(".json") }
        for file in files {
            let name = (file as NSString).deletingPathExtension
            if let data = try? db.read(from: file),
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
