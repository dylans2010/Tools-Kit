import Foundation

public class NetworkMonitorService: ObservableObject {
    public static let shared = NetworkMonitorService()
    private let store = DeveloperPersistentStore.shared

    @Published public var requests: [NetworkRequest] = []

    private init() { loadRequests() }

    public func loadRequests() { self.requests = store.networkRequests }

    public func logRequest(_ request: NetworkRequest) async throws {
        var current = store.networkRequests
        current.insert(request, at: 0)
        if current.count > 500 { current.removeLast() }
        store.saveNetworkRequests(current)
        let updatedRequests = current
        await MainActor.run { self.requests = updatedRequests }
    }
}
