import Foundation

struct JSONCoder {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? encoder.encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        try? decoder.decode(type, from: data)
    }

    static func encodeToString<T: Encodable>(_ value: T) -> String? {
        guard let data = encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decodeFromString<T: Decodable>(_ type: T.Type, from string: String) -> T? {
        guard let data = string.data(using: .utf8) else { return nil }
        return decode(type, from: data)
    }
}
