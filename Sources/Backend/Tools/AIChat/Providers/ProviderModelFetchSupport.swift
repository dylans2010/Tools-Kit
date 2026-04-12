import Foundation

enum ProviderModelFetchSupport {
    static func authRequest(url: URL, bearerKey: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("Bearer \(bearerKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    static func dataRequest(url: URL) -> URLRequest {
        URLRequest(url: url)
    }

    static func parseModelArray(_ data: Data, visionKeywords: [String] = ["vision", "gpt-4o", "claude", "gemini", "pixtral", "multimodal"]) throws -> [AIModel] {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let root = object as? [String: Any], let rows = root["data"] as? [[String: Any]] else {
            return []
        }

        return rows.compactMap { row in
            guard let id = row["id"] as? String else { return nil }
            let name = (row["name"] as? String) ?? id
            let context = row["context_length"] as? Int
            let lowered = id.lowercased()
            let vision = visionKeywords.contains { lowered.contains($0) }
            return AIModel(id: id, name: name, supportsVision: vision, contextLength: context)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
