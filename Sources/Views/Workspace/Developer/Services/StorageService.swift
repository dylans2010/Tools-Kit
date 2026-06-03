import Foundation

public class StorageService: ObservableObject {
    public static let shared = StorageService()
    private let store = DeveloperPersistentStore.shared

    @Published public var storageNodes: [StorageNode] = []

    private init() {
        loadStorage()
    }

    public func loadStorage() {
        self.storageNodes = store.storageNodes
    }

    public func provisionStorage(appID: UUID, name: String, type: String, sizeGB: Int) async throws {
        var current = store.storageNodes
        let newNode = StorageNode(
            appID: appID,
            name: name,
            type: type,
            usedSize: "0GB",
            totalSize: "\(sizeGB)GB",
            usage: 0.0
        )
        current.append(newNode)
        store.saveStorageNodes(current)
        await MainActor.run {
            self.storageNodes = current
        }
    }
}
