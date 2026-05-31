import Foundation

public class RemoteConfigService: ObservableObject {
    public static let shared = RemoteConfigService()
    private let store = DeveloperPersistentStore.shared

    @Published public var configs: [RemoteConfig] = []

    private init() { loadConfigs() }

    public func loadConfigs() { self.configs = store.remoteConfigs }

    public func saveConfig(_ config: RemoteConfig) async throws {
        var current = store.remoteConfigs
        if let index = current.firstIndex(where: { $0.id == config.id }) {
            current[index] = config
        } else {
            current.append(config)
        }
        store.saveRemoteConfigs(current)
        await MainActor.run { self.configs = current }
    }

    public func addConfig(_ config: RemoteConfig) {
        var current = store.remoteConfigs
        current.append(config)
        store.saveRemoteConfigs(current)
        self.configs = current
    }
}
