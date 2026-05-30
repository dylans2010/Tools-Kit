import Foundation

public class NetworkMonitoringService: ObservableObject {
    public static let shared = NetworkMonitoringService()
    private let store = DeveloperPersistentStore.shared

    @Published public var requests: [NetworkRequest] = []

    private init() {
        loadRequests()
    }

    public func loadRequests() {
        self.requests = store.networkRequests
    }

    public func logRequest(appID: UUID, url: String, method: String, statusCode: Int?, duration: TimeInterval) async {
        let request = NetworkRequest(appID: appID, url: url, method: method, statusCode: statusCode, duration: duration)
        var current = store.networkRequests
        current.insert(request, at: 0)

        // Keep last 100 requests
        if current.count > 100 {
            current.removeLast()
        }

        store.saveNetworkRequests(current)

        let updated = current
        await MainActor.run {
            self.requests = updated
        }
    }

    public func clearLogs() async {
        store.saveNetworkRequests([])
        await MainActor.run {
            self.requests = []
        }
    }
}
