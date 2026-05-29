import Foundation

public class DeveloperActivityService: ObservableObject {
    public static let shared = DeveloperActivityService()

    @Published public var activities: [DeveloperActivityEvent] = []

    private init() {
        loadActivities()
    }

    public func loadActivities() {
        // Awaiting backend integration
    }

    public func logEvent(eventType: DeveloperActivityEventType, appID: UUID? = nil, appName: String? = nil, recordID: UUID? = nil) async {
        let event = DeveloperActivityEvent(
            eventType: eventType,
            sourceAppID: appID,
            sourceAppName: appName,
            relatedRecordID: recordID
        )
        activities.insert(event, at: 0)
        // Awaiting backend integration
    }

    public func fetchRecentActivities(limit: Int = 10) async -> [DeveloperActivityEvent] {
        // Awaiting backend integration
        return Array(activities.prefix(limit))
    }
}
