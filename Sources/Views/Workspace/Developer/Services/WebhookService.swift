import Foundation

public class WebhookService: ObservableObject {
    public static let shared = WebhookService()

    @Published public var endpoints: [WebhookEndpoint] = []

    private init() {
        loadEndpoints()
    }

    public func loadEndpoints() {
        // Awaiting backend integration
    }

    public func createEndpoint(url: String, events: [WebhookEventType]) async throws {
        let endpoint = WebhookEndpoint(url: url, subscribedEvents: events, signingSecretKeyID: UUID())
        endpoints.append(endpoint)
        // Awaiting backend integration
    }

    public func updateEndpoint(_ endpoint: WebhookEndpoint) async throws {
        if let index = endpoints.firstIndex(where: { $0.id == endpoint.id }) {
            endpoints[index] = endpoint
        }
        // Awaiting backend integration
    }

    public func deleteEndpoint(id: UUID) async throws {
        endpoints.removeAll { $0.id == id }
        // Awaiting backend integration
    }

    public func testDelivery(endpointID: UUID) async throws -> (Int, String) {
        // Awaiting backend integration
        return (200, "OK")
    }

    public func fetchDeliveryLog(endpointID: UUID) async throws -> [WebhookDelivery] {
        // Awaiting backend integration
        return []
    }
}
