import Foundation

/// Protocol defining a structured SDK API endpoint.
/// Endpoints represent specific functionality exposed by SDK modules.
public protocol SDKEndpoint {
    var path: String { get }
    var method: SDKRoute.Method { get }
    var description: String { get }
    var requiredPermissions: [String] { get }

    func handle(request: SDKRequest) async throws -> SDKResponse
}

/// Base class for implementing SDK endpoints with built-in validation.
open class BaseSDKEndpoint: SDKEndpoint {
    public let path: String
    public let method: SDKRoute.Method
    public let description: String
    public let requiredPermissions: [String]

    public init(path: String, method: SDKRoute.Method = .get, description: String = "", requiredPermissions: [String] = []) {
        self.path = path
        self.method = method
        self.description = description
        self.requiredPermissions = requiredPermissions
    }

    open func handle(request: SDKRequest) async throws -> SDKResponse {
        fatalError("handle(request:) must be implemented by subclass")
    }

    public func validate(request: SDKRequest) throws {
        // Basic validation logic
        if request.path != path {
            throw SDKError.validationError(reason: "Path mismatch: expected \(path), got \(request.path)")
        }
    }
}
