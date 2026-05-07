import Foundation

/// A structured request for the SDK internal routing system.
public struct SDKRequest {
    public let endpoint: String
    public let parameters: [String: Any]

    public init(endpoint: String, parameters: [String: Any] = [:]) {
        self.endpoint = endpoint
        self.parameters = parameters
    }
}

/// A structured response from the SDK internal routing system.
public struct SDKResponse<T> {
    public let data: T?
    public let error: Error?

    public init(data: T? = nil, error: Error? = nil) {
        self.data = data
        self.error = error
    }

    public var isSuccess: Bool { error == nil }
}
