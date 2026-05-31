import Foundation

public class FeatureFlagService: ObservableObject {
    public static let shared = FeatureFlagService()
    private let store = DeveloperPersistentStore.shared

    @Published public var flags: [FeatureFlag] = []

    private init() {
        loadFlags()
    }

    public func loadFlags() {
        self.flags = store.featureFlags
    }

    public func createFlag(_ flag: FeatureFlag) async throws {
        var current = store.featureFlags
        current.append(flag)
        store.saveFeatureFlags(current)
        let updatedFlags = current
        await MainActor.run { self.flags = updatedFlags }
    }

    public func updateFlag(_ flag: FeatureFlag) async throws {
        var current = store.featureFlags
        if let index = current.firstIndex(where: { $0.id == flag.id }) {
            current[index] = flag
            current[index].updatedAt = Date()
            store.saveFeatureFlags(current)
            let updatedFlags = current
            await MainActor.run { self.flags = updatedFlags }
        }
    }

    public func toggleFlag(id: UUID) async throws {
        var current = store.featureFlags
        if let index = current.firstIndex(where: { $0.id == id }) {
            current[index].isEnabled.toggle()
            current[index].updatedAt = Date()
            store.saveFeatureFlags(current)
            let updatedFlags = current
            await MainActor.run { self.flags = updatedFlags }
        }
    }

    public func deleteFlag(id: UUID) async throws {
        var current = store.featureFlags
        current.removeAll { $0.id == id }
        store.saveFeatureFlags(current)
        let updatedFlags = current
        await MainActor.run { self.flags = updatedFlags }
    }
}
