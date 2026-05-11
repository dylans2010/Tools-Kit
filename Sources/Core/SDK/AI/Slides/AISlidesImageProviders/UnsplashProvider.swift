import Foundation

struct UnsplashProvider: AISlidesImageProvider {
    private let baseURL = "https://api.unsplash.com/search/photos"

    func imageURL(for query: String) async -> URL? {
        print("[UnsplashProvider] Searching for: \(query)")

        guard var components = URLComponents(string: baseURL) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "1"),
            URLQueryItem(name: "orientation", value: "landscape")
        ]

        guard let requestURL = components.url else { return nil }
        var request = URLRequest(url: requestURL)
        request.setValue("Client-ID unsplash_access_key", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("[UnsplashProvider] HTTP status: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else { return nil }
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let results = json?["results"] as? [[String: Any]],
                  let firstResult = results.first,
                  let urls = firstResult["urls"] as? [String: String],
                  let regularURL = urls["regular"] else {
                print("[UnsplashProvider] No results found")
                return nil
            }

            print("[UnsplashProvider] Found image: \(regularURL.prefix(60))")
            return URL(string: regularURL)
        } catch {
            print("[UnsplashProvider] Error: \(error.localizedDescription)")
            return nil
        }
    }
}
