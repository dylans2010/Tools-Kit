import Foundation

struct AgentAPIRequestBuilder: Sendable {
    init() {}

    func build(endpoint: URL, method: String = "POST", body: Encodable? = nil, headers: [String: String] = [:]) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    func buildRequest(_ apiRequest: AgentAPIRequest, endpoint: URL, headers: [String: String] = [:]) throws -> URLRequest {
        try build(endpoint: endpoint, method: "POST", body: apiRequest, headers: headers)
    }
}
