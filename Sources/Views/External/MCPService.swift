import Foundation

public final class MCPService {
    public static let shared = MCPService()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    public func send<R: Decodable>(
        request: MCPRequest,
        to server: MCPServer,
        authHeaders: [String: String]
    ) async throws -> R {
        guard let url = URL(string: server.baseURL) else {
            throw MCPError.invalidURL
        }

        // Security Enforcement: Enforce HTTPS unless server is explicitly trusted
        if !server.baseURL.lowercased().hasPrefix("https://") && !server.isTrusted {
            throw MCPError.connectionFailed("Insecure connection blocked. Only HTTPS is allowed unless the server is explicitly trusted.")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        for (key, value) in authHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let startTime = Date()
        let (data, response) = try await session.data(for: urlRequest)
        let latency = Date().timeIntervalSince(startTime) * 1000

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCPError.connectionFailed("No HTTP response received from \(server.baseURL)")
        }

        // Try to decode JSON response even for error status codes to capture MCP-specific error details
        let decoder = JSONDecoder()

        if !(200...299).contains(httpResponse.statusCode) {
            // Attempt to decode error response body
            if let errorResponse = try? decoder.decode(MCPResponse.self, from: data),
               let mcpError = errorResponse.error {
                throw MCPError.serverError(code: mcpError.code, message: mcpError.message, data: mcpError.data)
            }

            // Fallback for standard HTTP errors
            switch httpResponse.statusCode {
            case 401, 403:
                throw MCPError.authenticationFailed("HTTP \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
            case 400:
                throw MCPError.serverError(code: 400, message: "Bad Request: The server could not understand the request.", data: nil)
            case 406:
                throw MCPError.serverError(code: 406, message: "Not Acceptable: The server cannot produce a response matching the list of acceptable values.", data: nil)
            case 404:
                throw MCPError.invalidURL
            case 500...599:
                throw MCPError.connectionFailed("Server error (HTTP \(httpResponse.statusCode))")
            default:
                throw MCPError.connectionFailed("HTTP Status \(httpResponse.statusCode)")
            }
        }

        do {
            // Special handling for responses that might contain the latency
            // In a real implementation, we'd update the server model's latency property here.
            return try decoder.decode(R.self, from: data)
        } catch {
            let bodyString = String(data: data, encoding: .utf8) ?? "Unable to decode body"
            throw MCPError.decodeError("Failed to decode \(R.self): \(error.localizedDescription). Body: \(bodyString)")
        }
    }
}
