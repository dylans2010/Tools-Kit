import Foundation

public class WebhookService: ObservableObject {
    public static let shared = WebhookService()
    private let store = DeveloperPersistentStore.shared

    @Published public var endpoints: [WebhookEndpoint] = []

    private init() {
        loadEndpoints()
    }

    public func loadEndpoints() {
        self.endpoints = store.webhooks
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
        let responseBody = "OK"

        let delivery = WebhookDelivery(
            endpointID: endpointID,
            eventID: UUID(),
            eventType: endpoint.subscribedEvents.first ?? .appUpdated,
            payload: "{\"test\": true}",
            statusCode: statusCode,
            responseBody: responseBody,
            duration: 0.1
        )

        var current = store.webhookDeliveries
        current.insert(delivery, at: 0)
        store.saveWebhookDeliveries(current)

        return (statusCode, responseBody)
    }

    public func fetchDeliveryLog(endpointID: UUID) async throws -> [WebhookDelivery] {
        return store.webhookDeliveries.filter { $0.endpointID == endpointID }
    }
}
