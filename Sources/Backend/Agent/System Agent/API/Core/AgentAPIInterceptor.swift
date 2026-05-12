import Foundation

protocol AgentAPIInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest
}

struct AgentAuthInterceptor: AgentAPIInterceptor, Sendable {
    let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func intercept(_ request: URLRequest) -> URLRequest {
        var mutableRequest = request
        mutableRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }
}
