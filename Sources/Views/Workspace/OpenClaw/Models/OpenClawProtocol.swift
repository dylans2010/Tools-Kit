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

// Helper for dynamic JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) { value = x }
        else if let x = try? container.decode(Int.self) { value = x }
        else if let x = try? container.decode(Double.self) { value = x }
        else if let x = try? container.decode(String.self) { value = x }
        else if let x = try? container.decode([String: AnyCodable].self) { value = x.mapValues { $0.value } }
        else if let x = try? container.decode([AnyCodable].self) { value = x.map { $0.value } }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable can't decode value") }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let x = value as? Bool { try container.encode(x) }
        else if let x = value as? Int { try container.encode(x) }
        else if let x = value as? Double { try container.encode(x) }
        else if let x = value as? String { try container.encode(x) }
        else if let x = value as? [String: Any] { try container.encode(x.mapValues { AnyCodable($0) }) }
        else if let x = value as? [Any] { try container.encode(x.map { AnyCodable($0) }) }
    }
}
