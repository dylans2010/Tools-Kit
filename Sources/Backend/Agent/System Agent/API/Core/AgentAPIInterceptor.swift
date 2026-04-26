import Foundation

struct AgentAPIInterceptor {
    func intercept(_ request: URLRequest, transform: (URLRequest) -> URLRequest) -> URLRequest {
        transform(request)
    }
}
