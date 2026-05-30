import Foundation

public class LocalizationService: ObservableObject {
    public static let shared = LocalizationService()
    private let store = DeveloperPersistentStore.shared

    @Published public var keys: [LocalizationKey] = []

    private init() { loadKeys() }

    public func loadKeys() { self.keys = store.localizationKeys }

    public func saveKey(_ key: LocalizationKey) async throws {
        var current = store.localizationKeys
        if let index = current.firstIndex(where: { $0.id == key.id }) {
            current[index] = key
        } else {
            current.append(key)
        }
        store.saveLocalizationKeys(current)
        await MainActor.run { self.keys = current }
    }
}
