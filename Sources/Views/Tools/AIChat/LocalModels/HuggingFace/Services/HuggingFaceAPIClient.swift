import Foundation

class HuggingFaceAPIClient {
    static let shared = HuggingFaceAPIClient()
    private let baseURL = "https://huggingface.co/api/models"

    func searchModels(query: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> [HFModel] {
        var components = URLComponents(string: baseURL)!
        var queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "sort", value: "downloads"),
            URLQueryItem(name: "direction", value: "-1")
        ]

        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: query))
        }

        // Filter for GGUF models as they are common for local inference on iOS
        queryItems.append(URLQueryItem(name: "filter", value: "gguf"))

        components.queryItems = queryItems

        guard let url = components.url else {
            throw AIError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let models = try decoder.decode([HFModel].self, from: data)
            return models
        } catch {
            SDKLogStore.shared.log("HF API Client decoding error: \(error)", source: "HuggingFaceAPIClient", level: .error)
            throw AIError.decodingFailed
        }
    }
}
