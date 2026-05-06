import Foundation

/// Maps external API responses to SDK data nodes.
public final class SDKResponseParser {
    public static let shared = SDKResponseParser()

    private init() {}

    public func parse<T: Decodable>(_ data: Data, to type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    public func mapToDataNodes(_ data: [String: Any], scope: SDKScope) -> [SDKDataItem] {
        // Generic mapping logic
        let id = UUID()
        let title = (data["title"] as? String) ?? (data["name"] as? String) ?? "Untitled"
        return [SDKDataItem(id: id, scope: scope, title: title, payload: data, timestamp: Date())]
    }
}
