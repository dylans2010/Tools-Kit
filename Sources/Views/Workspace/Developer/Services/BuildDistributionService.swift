import Foundation

public class BuildDistributionService: ObservableObject {
    public static let shared = BuildDistributionService()
    private let store = DeveloperPersistentStore.shared

    @Published public var distributions: [BuildDistribution] = []

    private init() {
        loadDistributions()
    }

    public func loadDistributions() {
        self.distributions = store.distributions
    }

    public func createDistribution(appID: UUID, versionID: UUID, platform: String, channel: DistributionChannel) async {
        let distribution = BuildDistribution(appID: appID, versionID: versionID, platform: platform, channel: channel)
        var current = store.distributions
        current.append(distribution)
        store.saveDistributions(current)

        await MainActor.run {
            self.distributions = current
        }

        await DeveloperActivityService.shared.logEvent(
            eventType: .appUpdated,
            appID: appID,
            recordID: distribution.id
        )
    }

    public func updateStatus(id: UUID, status: DistributionStatus) async {
        var current = store.distributions
        if let index = current.firstIndex(where: { $0.id == id }) {
            current[index].status = status
            if status == .released {
                current[index].releasedAt = Date()
            }
            store.saveDistributions(current)

            let updated = current
            await MainActor.run {
                self.distributions = updated
            }
        }
    }
}
