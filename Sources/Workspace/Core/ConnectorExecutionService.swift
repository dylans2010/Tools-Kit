import Foundation

final class ConnectorExecutionService {
    static let shared = ConnectorExecutionService()

    private init() {}

    func performRequest(endpoint: ExternalAPIEndpoint, connector: ConnectorDefinition, body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw ConnectorError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = body

        // Apply Headers
        for (key, value) in endpoint.headers {
            let decryptedValue = PluginSecurityService.decryptHeader(value)
            request.addValue(decryptedValue, forHTTPHeaderField: key)
        }

        // Apply Auth
        try ConnectorAuthManager.shared.applyAuth(to: &request, connector: connector)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConnectorError.invalidResponse
        }

        return (data, httpResponse)
    }
}

enum ConnectorError: Error {
    case invalidURL
    case invalidResponse
    case authFailed
}
