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
        guard let endpoint = endpoints.first(where: { $0.id == endpointID }),
              let url = URL(string: endpoint.url) else {
            return (404, "Endpoint or URL invalid")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("ToolsKit-Webhook-Test", forHTTPHeaderField: "User-Agent")

        let payload = ["test": true, "timestamp": Date().timeIntervalSince1970]
        request.httpBody = try? JSONEncoder().encode(payload)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
            }
            return (0, "Unknown Response")
        } catch {
            return (0, error.localizedDescription)
        }
    }

    public func fetchDeliveryLog(endpointID: UUID) async throws -> [WebhookDelivery] {
        return []
    }
}
