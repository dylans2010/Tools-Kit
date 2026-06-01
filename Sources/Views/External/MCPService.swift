import Foundation

final class MCPService {
    static let shared = MCPService()

    private init() {}

    func send<R: Decodable>(
        request: MCPRequest,
        to server: MCPServer,
        authHeaders: [String: String]
    ) async throws -> R {
        guard let url = URL(string: server.baseURL) else { throw MCPError.invalidURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (key, value) in authHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCPError.connectionFailed("No HTTP response")
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw MCPError.authenticationFailed("HTTP \(httpResponse.statusCode)")
        }

        // Even for 400 Bad Request or other errors, try to decode the body
        // Many MCP servers return JSON-RPC error details in the 400 response body
        do {
            return try JSONDecoder().decode(R.self, from: data)
        } catch {
            if !(200...299).contains(httpResponse.statusCode) {
                throw MCPError.connectionFailed("HTTP Status \(httpResponse.statusCode)")
            }
            throw error
        }
    }
}
