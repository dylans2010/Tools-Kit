import Foundation

public class WebhookConnector: BaseConnector, ObservableObject {
    public let id = UUID()
    public let name = "Webhook"
    public let type: ConnectorType = .webhook
    @Published public var status: ConnectorStatus = .disconnected
    public var authFields: [AuthField] = [
        AuthField(label: "URL", placeholder: "https://example.com/webhook", isSecure: false, key: "url")
    ]
    @Published public var activityLog: [ConnectorEvent] = []

    private var url: URL?

    public init() {}

    public func authenticate(credentials: [String : String]) async throws {
        if let urlString = credentials["url"], let url = URL(string: urlString) {
            self.url = url
            status = .connected
        } else {
            throw NSError(domain: "WebhookConnector", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
    }

    public func sync() async throws {
        // No-op for webhook sync unless it's polling
    }

    public func testConnection() async throws -> Bool {
        return url != nil
    }

    public func disconnect() {
        url = nil
        status = .disconnected
    }

    public func execute(payload: [String: Any]) async throws -> Data {
        guard let url = url else { throw NSError(domain: "WebhookConnector", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
             throw NSError(domain: "WebhookConnector", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error"])
        }
        return data
    }
}
