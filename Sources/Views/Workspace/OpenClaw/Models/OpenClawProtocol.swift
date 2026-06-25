import Foundation

/// Represents a JSON-RPC 2.0 request for the OpenClaw protocol.
struct OpenClawRPCRequest: Codable {
    let jsonrpc: String
    let method: String
    let params: [String: AnyCodable]?
    let id: String

    enum CodingKeys: String, CodingKey {
        case jsonrpc, method, params, id
    }

    init(method: String, params: [String: AnyCodable]? = nil, id: String = UUID().uuidString) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
        self.id = id
    }

    /// Validates the request against OpenClaw protocol requirements.
    func validate() throws {
        guard jsonrpc == "2.0" else {
            throw OpenClawError.protocolError("Invalid JSON-RPC version: \(jsonrpc)")
        }
        guard !method.isEmpty else {
            throw OpenClawError.protocolError("RPC method cannot be empty")
        }
        guard !id.isEmpty else {
            throw OpenClawError.protocolError("RPC id cannot be empty")
        }

        // Connect method specific validation
        if method == "connect" {
            if let params = params {
                // If we are at authenticating state, we expect nonce and device_id
                // But the initial connect might have empty params
            }
        }
    }
}

/// Represents a JSON-RPC 2.0 response from the OpenClaw gateway.
struct OpenClawRPCResponse: Codable {
    let jsonrpc: String
    let result: AnyCodable?
    let error: OpenClawRPCError?
    let id: String?

    func validate() throws {
        guard jsonrpc == "2.0" else {
            throw OpenClawError.protocolError("Invalid JSON-RPC version in response: \(jsonrpc)")
        }
    }
}

/// Represents a JSON-RPC 2.0 error object.
struct OpenClawRPCError: Codable {
    let code: Int
    let message: String
    let data: AnyCodable?
}

/// Represents an asynchronous event emitted by the OpenClaw gateway.
struct OpenClawEvent: Codable {
    let event: String
    let payload: AnyCodable
}
