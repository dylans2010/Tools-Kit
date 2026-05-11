import Foundation

struct PexelsProvider: AISlidesImageProvider {
    private let baseURL = "https://api.pexels.com/v1/search"

    func imageURL(for query: String) async -> URL? {
        print("[PexelsProvider] Searching for: \(query)")

        guard var components = URLComponents(string: baseURL) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "1"),
            URLQueryItem(name: "orientation", value: "landscape")
        ]

        guard let requestURL = components.url else { return nil }
        var request = URLRequest(url: requestURL)
        request.setValue("pexels_api_key", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("[PexelsProvider] HTTP status: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else { return nil }
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let photos = json?["photos"] as? [[String: Any]],
                  let firstPhoto = photos.first,
                  let src = firstPhoto["src"] as? [String: String],
                  let largeURL = src["large2x"] ?? src["large"] ?? src["original"] else {
                print("[PexelsProvider] No results found")
                return nil
            }

            print("[PexelsProvider] Found image: \(largeURL.prefix(60))")
            return URL(string: largeURL)
        } catch {
            print("[PexelsProvider] Error: \(error.localizedDescription)")
            return nil
        }
    }
}
