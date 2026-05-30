import Foundation

/**
 SYSTEM DOMAIN: Observability
 RESPONSIBILITY: Tracks and logs administrative and development activity within the portal.
 */
public class DeveloperActivityService: ObservableObject {
    public static let shared = DeveloperActivityService()
    private let store = DeveloperPersistentStore.shared

    @Published public var activities: [DeveloperActivityEvent] = []

    private init() {
        loadActivities()
    }

    public func loadActivities() {
        self.activities = store.activities
    }

    public func logEvent(eventType: DeveloperActivityEventType, appID: UUID? = nil, appName: String? = nil, recordID: UUID? = nil) async {
        let event = DeveloperActivityEvent(
            eventType: eventType,
            sourceAppID: appID,
            sourceAppName: appName ?? store.apps.first(where: { $0.id == appID })?.name,
            relatedRecordID: recordID
        )

        var currentActivities = store.activities
        currentActivities.insert(event, at: 0)

        // Cap activity log
        if currentActivities.count > 500 {
            currentActivities.removeLast()
        }

        store.saveActivities(currentActivities)

        let updatedActivities = currentActivities
        await MainActor.run {
            self.activities = updatedActivities
        }
    }

    public func fetchRecentActivities(limit: Int = 10) async -> [DeveloperActivityEvent] {
        return Array(activities.prefix(limit))
    }

    public func clearActivities() async {
        store.saveActivities([])
        await MainActor.run {
            self.activities = []
        }
    }
}
