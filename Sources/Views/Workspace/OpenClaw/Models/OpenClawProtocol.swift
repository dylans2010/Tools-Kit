import Foundation

struct OpenClawRPCRequest: Codable {
    let jsonrpc: String = "2.0"
    let method: String
    let params: [String: AnyCodable]
    let id: String

    init(method: String, params: [String: AnyCodable] = [:], id: String = UUID().uuidString) {
        self.method = method
        self.params = params
        self.id = id
    }
}

struct OpenClawRPCResponse: Codable {
    let jsonrpc: String
    let result: AnyCodable?
    let error: OpenClawRPCError?
    let id: String?
}

struct OpenClawRPCError: Codable {
    let code: Int
    let message: String
    let data: AnyCodable?
}

struct OpenClawEvent: Codable {
    let event: String
    let payload: AnyCodable
}

