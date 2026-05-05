import Foundation

final class ConnectorAuthManager {
    static let shared = ConnectorAuthManager()

    private init() {}

    func applyAuth(to request: inout URLRequest, connector: ConnectorDefinition) throws {
        let auth = connector.auth

        switch auth.type {
        case .none:
            break
        case .apiKey:
            if let key = auth.apiKey {
                request.addValue(key, forHTTPHeaderField: "X-API-Key")
            }
        case .bearer:
            if let token = auth.bearerToken {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        case .oauth:
            // Simplified OAuth: Assume token is already refreshed or handle refresh logic
            if let token = auth.bearerToken {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        for (key, value) in auth.customHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }
    }
}
