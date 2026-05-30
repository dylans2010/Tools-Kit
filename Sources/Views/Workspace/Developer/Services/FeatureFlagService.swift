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

    public func createFlag(appID: UUID, key: String, description: String) async {
        let flag = FeatureFlag(appID: appID, key: key, description: description)
        var current = store.featureFlags
        current.append(flag)
        store.saveFeatureFlags(current)

        await MainActor.run {
            self.flags = current
        }
    }

    public func toggleFlag(id: UUID) async {
        var current = store.featureFlags
        if let index = current.firstIndex(where: { $0.id == id }) {
            current[index].isEnabled.toggle()
            store.saveFeatureFlags(current)

            let updated = current
            await MainActor.run {
                self.flags = updated
            }
        }
    }

    public func updateRollout(id: UUID, percentage: Int) async {
        var current = store.featureFlags
        if let index = current.firstIndex(where: { $0.id == id }) {
            current[index].rolloutPercentage = max(0, min(100, percentage))
            store.saveFeatureFlags(current)

            let updated = current
            await MainActor.run {
                self.flags = updated
            }
        }
    }
}
