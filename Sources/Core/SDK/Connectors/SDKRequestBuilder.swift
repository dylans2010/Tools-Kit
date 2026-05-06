import Foundation

/// Build dynamic API requests for connectors.
public final class SDKRequestBuilder {
    public var url: URL?
    public var method: String = "GET"
    public var headers: [String: String] = [:]
    public var body: Data?

    public init() {}

    public func setEndpoint(_ endpoint: String, params: [String: String] = [:]) -> SDKRequestBuilder {
        var components = URLComponents(string: endpoint)
        if !params.isEmpty {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        self.url = components?.url
        return self
    }

    public func addHeader(_ key: String, value: String) -> SDKRequestBuilder {
        headers[key] = value
        return self
    }

    public func setJSONBody(_ dict: [String: Any]) -> SDKRequestBuilder {
        self.body = try? JSONSerialization.data(withJSONObject: dict)
        addHeader("Content-Type", "application/json")
        return self
    }

    public func build() -> URLRequest? {
        guard let url = url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }
}
