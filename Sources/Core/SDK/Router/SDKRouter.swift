import Foundation

/// On-device API routing system for the SDK.
public final class SDKRouter: SDKRouterProtocol {
    public static let shared = SDKRouter()

    private var registeredRoutes: [String: SDKRoute] = [:]
    private var handlers: [String: (SDKRequest) async throws -> SDKResponse] = [:]

    private init() {}

    public func register(_ route: SDKRoute) {
        registeredRoutes[route.path] = route
    }

    public func registerHandler(_ path: String, method: SDKRoute.Method = .get, handler: @escaping (SDKRequest) async throws -> SDKResponse) {
        let route = SDKRoute(path: path, method: method, module: extractModule(from: path))
        registeredRoutes[path] = route
        handlers["\(method.rawValue):\(path)"] = handler
    }

    public func handle(_ request: SDKRequest) async throws -> SDKResponse {
        let key = "\(request.method.rawValue):\(request.path)"

        guard let handler = handlers[key] else {
            return SDKResponse(
                requestId: request.id,
                status: .notFound,
                error: "No handler for \(request.method.rawValue) \(request.path)"
            )
        }

        let startTime = Date()
        do {
            var response = try await handler(request)
            response.latency = Date().timeIntervalSince(startTime)
            return response
        } catch {
            return SDKResponse(
                requestId: request.id,
                status: .error,
                error: error.localizedDescription
            )
        }
    }

    public func routes() -> [SDKRoute] {
        return Array(registeredRoutes.values).sorted { $0.path < $1.path }
    }

    public func registerDefaultRoutes() {
        registerHandler("/sdk/health", method: .get) { _ in
            SDKResponse(requestId: UUID(), status: .success, data: ["status": "healthy"])
        }

        registerHandler("/mail/list", method: .get) { request in
            let messages = await SDKMailService.shared.listMessages()
            return SDKResponse(requestId: request.id, status: .success, data: ["count": "\(messages.count)"])
        }
    }

    private func extractModule(from path: String) -> String {
        let components = path.split(separator: "/").map(String.init)
        return components.count > 1 ? components[1] : "sdk"
    }
}

/// Protocol for the SDK internal API router.
public protocol SDKRouterProtocol {
    func register(_ route: SDKRoute)
    func handle(_ request: SDKRequest) async throws -> SDKResponse
    func routes() -> [SDKRoute]
}

/// Route Definition
public struct SDKRoute: Identifiable, Codable {
    public let id: UUID
    public let path: String
    public let method: Method
    public let module: String
    public let description: String

    public enum Method: String, Codable, CaseIterable {
        case get = "GET", post = "POST", put = "PUT", delete = "DELETE"
    }

    public init(path: String, method: Method = .get, module: String = "sdk", description: String = "") {
        self.id = UUID()
        self.path = path
        self.method = method
        self.module = module
        self.description = description
    }
}
