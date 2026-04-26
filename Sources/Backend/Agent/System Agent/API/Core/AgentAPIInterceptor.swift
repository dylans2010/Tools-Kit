import Foundation

public protocol AgentAPIInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest
}

public struct AgentAuthInterceptor: AgentAPIInterceptor {
    let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func intercept(_ request: URLRequest) -> URLRequest {
        var mutableRequest = request
        mutableRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }
}
