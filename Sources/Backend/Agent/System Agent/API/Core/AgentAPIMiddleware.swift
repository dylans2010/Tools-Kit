import Foundation

struct AgentAPIMiddleware {
    typealias Middleware = (URLRequest) -> URLRequest

    private var middlewares: [Middleware] = []

    mutating func use(_ middleware: @escaping Middleware) {
        middlewares.append(middleware)
    }

    func apply(to request: URLRequest) -> URLRequest {
        middlewares.reduce(request) { current, middleware in middleware(current) }
    }
}
