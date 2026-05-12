import Foundation

enum AIResponseDecoderError: LocalizedError, Sendable {
    case invalidJSON
    case missingRequiredKeys([String])
    case typeMismatch(path: String, expected: String, actual: String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "The AI response was not valid JSON."
        case .missingRequiredKeys(let keys):
            return "The AI response was missing required fields: \(keys.joined(separator: ", "))."
        case .typeMismatch(let path, let expected, let actual):
            return "The AI response contained an unexpected type at \(path). Expected \(expected) but found \(actual)."
        case .decodingFailed(let reason):
            return "Failed to decode AI response: \(reason)"
        }
    }
}

indirect enum AIJSONType {
    case string
    case int
    case double
    case bool
    case array(AIJSONType)
    case object([String: AIJSONType])
}

struct AIResponseDecoder: @unchecked Sendable {
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func decode<T: Decodable>(_ type: T.Type, from jsonString: String, schema: AIJSONType) throws -> T {
        guard let data = jsonString.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) else {
            throw AIResponseDecoderError.invalidJSON
        }

        try validate(value: root, schema: schema, path: "$")

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw AIResponseDecoderError.decodingFailed(error.localizedDescription)
        }
    }

    private func validate(value: Any, schema: AIJSONType, path: String) throws {
        switch schema {
        case .string:
            guard value is String else {
                throw AIResponseDecoderError.typeMismatch(path: path, expected: "string", actual: describe(value))
            }
        case .int:
            guard let number = value as? NSNumber, number.doubleValue.rounded() == number.doubleValue else {
                throw AIResponseDecoderError.typeMismatch(path: path, expected: "integer", actual: describe(value))
            }
        case .double:
            guard value is NSNumber else {
                throw AIResponseDecoderError.typeMismatch(path: path, expected: "number", actual: describe(value))
            }
        case .bool:
            guard value is Bool else {
                throw AIResponseDecoderError.typeMismatch(path: path, expected: "boolean", actual: describe(value))
            }
        case .array(let itemSchema):
            guard let array = value as? [Any] else {
                throw AIResponseDecoderError.typeMismatch(path: path, expected: "array", actual: describe(value))
            }
            try array.enumerated().forEach { index, element in
                try validate(value: element, schema: itemSchema, path: "\(path)[\(index)]")
            }
        case .object(let required):
            guard let dict = value as? [String: Any] else {
                throw AIResponseDecoderError.typeMismatch(path: path, expected: "object", actual: describe(value))
            }
            let missing = required.keys.filter { dict[$0] == nil }
            if !missing.isEmpty {
                throw AIResponseDecoderError.missingRequiredKeys(missing)
            }
            try required.forEach { key, schema in
                if let nested = dict[key] {
                    try validate(value: nested, schema: schema, path: "\(path).\(key)")
                }
            }
        }
    }

    private func describe(_ value: Any) -> String {
        switch value {
        case is NSNull:
            return "null"
        case is String:
            return "string"
        case let number as NSNumber:
            if number.doubleValue.rounded() == number.doubleValue {
                return "integer"
            }
            return "number"
        case is Bool:
            return "boolean"
        case is [Any]:
            return "array"
        case is [String: Any]:
            return "object"
        default:
            return "\(type(of: value))"
        }
    }
}
