import Foundation

/// Protocol for the SDK internal API router.
public protocol SDKRouterProtocol {
    func register(_ route: SDKRoute)
    func handle(_ request: SDKRequest) async throws -> SDKResponse
    func routes() -> [SDKRoute]
}

/// On-device API routing system for the SDK.
/// Routes internal calls to the appropriate service handlers.
public final class SDKRouter: SDKRouterProtocol {
    public static let shared = SDKRouter()

    private var registeredRoutes: [String: SDKRoute] = [:]
    private var handlers: [String: (SDKRequest) async throws -> SDKResponse] = [:]

    private init() {}

    // MARK: - Route Registration

    public func register(_ route: SDKRoute) {
        registeredRoutes[route.path] = route
    }

    public func registerHandler(_ path: String, method: SDKRoute.Method = .get, handler: @escaping (SDKRequest) async throws -> SDKResponse) {
        let route = SDKRoute(path: path, method: method, module: extractModule(from: path))
        registeredRoutes[path] = route
        handlers["\(method.rawValue):\(path)"] = handler
    }

    // MARK: - Request Handling

    public func handle(_ request: SDKRequest) async throws -> SDKResponse {
        let key = "\(request.method.rawValue):\(request.path)"

        guard let handler = handlers[key] else {
            return SDKResponse(
                requestId: request.id,
                status: .notFound,
                data: [:],
                error: "No handler registered for \(request.method.rawValue) \(request.path)"
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
                data: [:],
                error: error.localizedDescription
            )
        }
    }

    // MARK: - Route Inspection

    public func routes() -> [SDKRoute] {
        return Array(registeredRoutes.values).sorted { $0.path < $1.path }
    }

    public func hasRoute(_ path: String) -> Bool {
        return registeredRoutes[path] != nil
    }

    // MARK: - Default Routes

    public func registerDefaultRoutes() {
        registerHandler("/sdk/health", method: .get) { _ in
            SDKResponse(requestId: UUID(), status: .success, data: ["status": "healthy", "version": "2.0.0"])
        }

        registerHandler("/sdk/info", method: .get) { _ in
            let env = SDKEnvironment.shared.configuration
            return SDKResponse(requestId: UUID(), status: .success, data: [
                "version": env.sdkVersion,
                "build": "\(env.buildNumber)",
                "environment": env.environment.rawValue
            ])
        }

        registerHandler("/sdk/services", method: .get) { _ in
            let services = await ServiceContainer.shared.registeredServiceNames()
            return SDKResponse(requestId: UUID(), status: .success, data: ["services": services.joined(separator: ",")])
        }

        registerHandler("/mail/send", method: .post) { request in
            let to = request.parameters["to"] ?? ""
            let subject = request.parameters["subject"] ?? ""
            let body = request.parameters["body"] ?? ""
            try await SDKMailService.shared.send(to: to, subject: subject, body: body)
            return SDKResponse(requestId: request.id, status: .success, data: ["sent": "true"])
        }

        registerHandler("/mail/list", method: .get) { request in
            let messages = await SDKMailService.shared.listMessages()
            return SDKResponse(requestId: request.id, status: .success, data: ["count": "\(messages.count)"])
        }

        registerHandler("/notebooks/create", method: .post) { request in
            let title = request.parameters["title"] ?? "Untitled"
            let notebook = try await SDKNotebookService.shared.createNotebook(title: title)
            return SDKResponse(requestId: request.id, status: .success, data: ["id": notebook.id.uuidString, "title": notebook.title])
        }

        registerHandler("/notebooks/list", method: .get) { request in
            let notebooks = await SDKNotebookService.shared.listNotebooks()
            return SDKResponse(requestId: request.id, status: .success, data: ["count": "\(notebooks.count)"])
        }

        registerHandler("/meet/create", method: .post) { request in
            let title = request.parameters["title"] ?? "Meeting"
            let session = try await SDKMeetService.shared.createSession(title: title)
            return SDKResponse(requestId: request.id, status: .success, data: ["id": session.id.uuidString])
        }

        registerHandler("/articles/create", method: .post) { request in
            let title = request.parameters["title"] ?? "Untitled"
            let content = request.parameters["content"] ?? ""
            let article = try await SDKArticleService.shared.createArticle(title: title, content: content)
            return SDKResponse(requestId: request.id, status: .success, data: ["id": article.id.uuidString])
        }

        registerHandler("/articles/list", method: .get) { request in
            let articles = await SDKArticleService.shared.listArticles()
            return SDKResponse(requestId: request.id, status: .success, data: ["count": "\(articles.count)"])
        }
    }

    private func extractModule(from path: String) -> String {
        let components = path.split(separator: "/").map(String.init)
        return components.count > 1 ? components[1] : "sdk"
    }
}

// MARK: - Route Definition

public struct SDKRoute: Identifiable {
    public let id: UUID
    public let path: String
    public let method: Method
    public let module: String
    public let description: String

    public enum Method: String, Codable, CaseIterable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    public init(path: String, method: Method = .get, module: String = "sdk", description: String = "") {
        self.id = UUID()
        self.path = path
        self.method = method
        self.module = module
        self.description = description
    }
}
