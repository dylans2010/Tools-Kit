import Foundation

/// Internal API Routing system for WorkspaceSDK.
/// Orchestrates calls between the SDK interface and underlying feature services.
public final class SDKRouter {
    public static let shared = SDKRouter()

    private var handlers: [String: (SDKRequest) async throws -> Any] = [:]
    private let lock = NSLock()

    private init() {}

    public func register(endpoint: String, handler: @escaping (SDKRequest) async throws -> Any) {
        lock.lock()
        defer { lock.unlock() }
        handlers[endpoint] = handler
    }

    public func call<T>(endpoint: String, parameters: [String: Any] = [:]) async throws -> SDKResponse<T> {
        let request = SDKRequest(endpoint: endpoint, parameters: parameters)

        guard let handler = handlers[endpoint] else {
            throw SDKRouterError.endpointNotFound(endpoint)
        }

        do {
            let result = try await handler(request)
            guard let typedResult = result as? T else {
                throw SDKRouterError.invalidResponseType(expected: String(describing: T.self), actual: String(describing: type(of: result)))
            }
            return SDKResponse(data: typedResult)
        } catch {
            return SDKResponse(error: error)
        }
    }
}

public enum SDKRouterError: Error {
    case endpointNotFound(String)
    case invalidResponseType(expected: String, actual: String)
}
