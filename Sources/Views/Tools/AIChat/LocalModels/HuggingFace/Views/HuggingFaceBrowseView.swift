import Foundation
import Combine

class HuggingFaceAPIClient: ObservableObject {
    static let shared = HuggingFaceAPIClient()

    private let session = URLSession.shared
    private let baseURL = URL(string: "https://huggingface.co/api")!

    func searchModels(query: String, offset: Int) async throws -> [HFModel] {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("models"), resolvingAgainstBaseURL: false)!
        var queryItems = [URLQueryItem(name: "limit", value: "20"),
                          URLQueryItem(name: "offset", value: "\(offset)")]
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: query))
        }
        urlComponents.queryItems = queryItems

        let (data, _) = try await session.data(from: urlComponents.url!)
        let models = try JSONDecoder().decode([HFModel].self, from: data)
        return models
    }
}
