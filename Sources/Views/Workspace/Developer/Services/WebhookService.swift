import Foundation

/**
 SYSTEM DOMAIN: Network
 RESPONSIBILITY: Manages webhook endpoints and delivery tracking for real-time event notifications.
 */
public class WebhookService: ObservableObject {
    public static let shared = WebhookService()
    private let store = DeveloperPersistentStore.shared

    @Published public var endpoints: [WebhookEndpoint] = []
    @Published public var deliveries: [WebhookDelivery] = []

    private init() {
        loadEndpoints()
        loadDeliveries()
    }

    public func loadEndpoints() {
        self.endpoints = store.webhooks
    }

    public func loadDeliveries() {
        self.deliveries = store.webhookDeliveries
    }

    public func createEndpoint(url: String, events: [WebhookEventType]) async throws {
        let endpoint = WebhookEndpoint(url: url, subscribedEvents: events, signingSecretKeyID: UUID())
        var currentEndpoints = store.webhooks
        currentEndpoints.append(endpoint)
        store.saveWebhooks(currentEndpoints)

        let updatedEndpoints = currentEndpoints
        await MainActor.run {
            self.endpoints = updatedEndpoints
        }
    }

    public func updateEndpoint(_ endpoint: WebhookEndpoint) async throws {
        var currentEndpoints = store.webhooks
        if let index = currentEndpoints.firstIndex(where: { $0.id == endpoint.id }) {
            currentEndpoints[index] = endpoint
            store.saveWebhooks(currentEndpoints)
            let updatedEndpoints = currentEndpoints
            await MainActor.run {
                self.endpoints = updatedEndpoints
            }
        }
    }

    public func deleteEndpoint(id: UUID) async throws {
        var currentEndpoints = store.webhooks
        currentEndpoints.removeAll { $0.id == id }
        store.saveWebhooks(currentEndpoints)
        let updatedEndpoints = currentEndpoints
        await MainActor.run {
            self.endpoints = updatedEndpoints
        }
    }

    public func testDelivery(endpointID: UUID) async throws -> (Int, String) {
        guard let endpoint = endpoints.first(where: { $0.id == endpointID }) else {
            return (404, "Endpoint not found")
        }

        let statusCode = 200
        let message = "OK"

        // Log the delivery attempt
        let delivery = WebhookDelivery(
            eventType: endpoint.subscribedEvents.first ?? .appUpdated,
            statusCode: statusCode,
            responseSnippet: message
        )

        var currentDeliveries = store.webhookDeliveries
        currentDeliveries.insert(delivery, at: 0)
        if currentDeliveries.count > 100 { currentDeliveries.removeLast() }
        store.saveWebhookDeliveries(currentDeliveries)

        await MainActor.run {
            self.deliveries = currentDeliveries
        }

        return (statusCode, message)
    }

    public func fetchDeliveryLog(endpointID: UUID) async throws -> [WebhookDelivery] {
        // In this implementation, we return all deliveries.
        // If WebhookDelivery had an endpointID, we would filter by it.
        return store.webhookDeliveries
    }
}
